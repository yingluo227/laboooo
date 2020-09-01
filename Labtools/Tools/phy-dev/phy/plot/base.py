# -*- coding: utf-8 -*-

"""Base OpenGL classes."""


#------------------------------------------------------------------------------
# Imports
#------------------------------------------------------------------------------

import gc
import logging
import re
from timeit import default_timer
import traceback

import numpy as np

from phylib.utils import connect, emit, Bunch
from phy.gui.qt import Qt, QEvent, QOpenGLWindow
from . import gloo
from .gloo import gl
from .transform import TransformChain, Clip, pixels_to_ndc
from .utils import _load_shader, _get_array, BatchAccumulator


logger = logging.getLogger(__name__)


#------------------------------------------------------------------------------
# Utils
#------------------------------------------------------------------------------

def indent(text):
    return '\n'.join('    ' + l.strip() for l in text.splitlines())


#------------------------------------------------------------------------------
# Base spike visual
#------------------------------------------------------------------------------

class BaseVisual(object):
    """A Visual represents one object (or homogeneous set of objects).

    It is rendered with a single pass of a single gloo program with a single type of GL primitive.

    Main abstract methods
    ---------------------

    validate
        takes as input the visual's parameters, set the default values, and validates all
        values
    vertex_count
        takes as input the visual's parameters, and return the total number of vertices
    set_data
        takes as input the visual's parameters, and ends with update calls to the underlying
        OpenGL program: `self.program[name] = data`

    Notes
    -----

    * set_data MUST set self.n_vertices (necessary for a_box_index in layouts)
    * set_data MUST call `self.emit_visual_set_data()` at the end, and return the data

    """

    # Variables that are supposed to be lists, and that should not be
    # batched together when adding batch data.
    _noconcat = ()

    # Variables that need to be set in __init__() rather than __setdata__() because
    # the shader depends on it.
    _init_keywords = ()

    _hidden = False

    def __init__(self):
        self.gl_primitive_type = None
        self.transforms = TransformChain()
        self.inserter = GLSLInserter()
        self.inserter.insert_vert('uniform vec2 u_window_size;', 'header')
        # The program will be set by the canvas when the visual is
        # added to the canvas.
        self.n_vertices = 0
        self.program = None
        self._acc = BatchAccumulator()

    def emit_visual_set_data(self):
        """Emit canvas.visual_set_data event after data has been set in the visual."""
        emit('visual_set_data', self.canvas, self)

    # Visual definition
    # -------------------------------------------------------------------------

    def set_shader(self, name):
        """Set the built-in vertex and fragment shader."""
        self.vertex_shader = _load_shader(name + '.vert')
        self.fragment_shader = _load_shader(name + '.frag')

    def set_primitive_type(self, primitive_type):
        """Set the primitive type (points, lines, line_strip, line_fan, triangles)."""
        self.gl_primitive_type = primitive_type

    def on_draw(self):
        """Draw the visual."""
        # Skip the drawing if the program hasn't been built yet.
        # The program is built by the layout.
        if self.program is not None:
            # Draw the program.
            self.program.draw(self.gl_primitive_type)
        else:  # pragma: no cover
            logger.debug("Skipping drawing visual `%s` because the program "
                         "has not been built yet.", self)

    def on_resize(self, width, height):
        """Update the window size in the OpenGL program."""
        s = self.program._vertex.code + '\n' + self.program.fragment.code
        # HACK: ensure that u_window_size appears somewhere in the shaders body (discarding
        # the headers).
        s = s.replace('uniform vec2 u_window_size;', '')
        if 'u_window_size' in s:
            self.program['u_window_size'] = (width, height)

    def hide(self):
        """Hide the visual."""
        self._hidden = True

    def show(self):
        """Show the visual."""
        self._hidden = False

    def close(self):
        """Close the visual."""
        self.program._deactivate()
        del self.program
        gc.collect()

    # To override
    # -------------------------------------------------------------------------

    @staticmethod
    def validate(**kwargs):
        """Make consistent the input data for the visual."""
        return kwargs  # pragma: no cover

    @staticmethod
    def vertex_count(**kwargs):
        """Return the number of vertices as a function of the input data."""
        return 0  # pragma: no cover

    def set_data(self):
        """Set data to the program.

        Must be called *after* attach(canvas), because the program is built
        when the visual is attached to the canvas.

        """
        raise NotImplementedError()

    # Batch and PlotCanvas
    # -------------------------------------------------------------------------

    def add_batch_data(self, **kwargs):
        """Prepare data to be added later with `PlotCanvas.add_visual()`."""
        box_index = kwargs.pop('box_index', None)
        data = self.validate(**kwargs)
        # WARNING: size should be the number of items for correct batch array creation,
        # not the number of vertices.
        self._acc.add(
            data, box_index=box_index, n_items=data._n_items,
            n_vertices=data._n_vertices, noconcat=self._noconcat)

    def reset_batch(self):
        """Reinitialize the batch."""
        self._acc.reset()

    def set_box_index(self, box_index, data=None):
        """Set the visual's box index. This is used by layouts (e.g. subplot indices)."""
        # data is the output of validate_data. This is used by the child class TextVisual.
        assert box_index is not None
        n = self.n_vertices
        if not isinstance(box_index, np.ndarray):
            k = len(box_index)
            a_box_index = _get_array(box_index, (n, k))
        else:
            a_box_index = box_index
        if a_box_index.ndim == 1:  # pragma: no cover
            a_box_index = np.c_[a_box_index.ravel()]
        assert a_box_index.ndim == 2
        assert a_box_index.shape[0] == n
        self.program['a_box_index'] = a_box_index.astype(np.float32)


#------------------------------------------------------------------------------
# Build program with layouts
#------------------------------------------------------------------------------

def _get_glsl(to_insert, shader_type=None, location=None, exclude_origins=()):
    """From a `to_insert` list of (shader_type, location, origin, snippet), return the
    concatenated snippet that satisfies the specified shader type, location, and origin."""
    return '\n'.join((
        snippet
        for (shader_type_, location_, origin_, snippet) in to_insert
        if shader_type_ == shader_type and location_ == location and
        origin_ not in exclude_origins
    ))


class GLSLInserter(object):
    """Object used to insert GLSL snippets into shader code.

    This class provides methods to specify the snippets to insert, and the
    `insert_into_shaders()` method inserts them into a vertex and fragment shader.

    """

    def __init__(self):
        self._to_insert = []  # list of tuples (shader_type, location, origin, glsl)

    def _init_insert(self):
        self.insert_vert('vec2 temp_pos_tr = {{ var }};\n'
                         'vec2 pos_orig = temp_pos_tr;\n',  # keep original value.
                         'before_transforms', index=0)
        self.insert_vert('gl_Position = vec4(temp_pos_tr, 0., 1.);',
                         'after_transforms', index=0)
        self.insert_vert('varying vec2 v_temp_pos_tr;\n', 'header', index=0)
        self.insert_frag('varying vec2 v_temp_pos_tr;\n', 'header', index=0)

    def _insert(self, shader_type, glsl, location, origin=None, index=None):
        assert location in (
            'header',
            'before_transforms',
            'transforms',
            'after_transforms',
        )
        item = (shader_type, location, origin, glsl)
        if index is None:
            self._to_insert.append(item)
        else:
            self._to_insert.insert(index, item)

    def insert_vert(self, glsl, location='transforms', origin=None, index=None):
        """Insert a GLSL snippet into the vertex shader.

        Parameters
        ----------

        glsl : str
            The GLSL code to insert.
        location : str
            Where to insert the GLSL code. Can be:

            * `header`: declaration of GLSL variables
            * `before_transforms`: just before the transforms in the vertex shader
            * `transforms`: where the GPU transforms are applied in the vertex shader
            * `after_transforms`: just after the GPU transforms

        origin : Interact
            The interact object that adds this GLSL snippet. Should be discared by
            visuals that are added with that interact object in `exclude_origins`.
        index : int
            Index of the snippets list to insert the snippet.

        """
        self._insert('vert', glsl, location, origin=origin, index=index)

    def insert_frag(self, glsl, location=None, origin=None, index=None):
        """Insert a GLSL snippet into the fragment shader. See `insert_vert()`."""
        self._insert('frag', glsl, location, origin=origin, index=index)

    def add_transform_chain(self, tc):
        """Insert all GLSL snippets from a transform chain."""
        # Generate the transforms snippet.
        for where, t, origin in tc._transforms:
            if where != 'gpu':
                continue
            if isinstance(t, Clip):
                # Set the varying value in the vertex shader.
                self.insert_vert('v_temp_pos_tr = temp_pos_tr;', origin=origin)
                continue
            self.insert_vert(t.glsl('temp_pos_tr'), origin=origin)
        # Clipping.
        clip = tc.get('Clip')
        if clip:
            self.insert_frag(clip.glsl('v_temp_pos_tr'), 'before_transforms', origin=origin)

    def insert_into_shaders(self, vertex, fragment, exclude_origins=()):
        """Insert all GLSL snippets in a vertex and fragment shaders.

        Parameters
        ----------

        vertex : str
            GLSL code of the vertex shader
        fragment : str
            GLSL code of the fragment shader
        exclude_origins : list-like
            List of interact instances to exclude when inserting the shaders.

        Notes
        -----

        The vertex shader typicall contains `gl_Position = transform(data_var_name);`
        which is automatically detected, and the GLSL transformations are inserted there.

        Snippets can contain `{{ var }}` placeholders for the transformed variable name.

        """
        assert None not in exclude_origins
        self._init_insert()
        # to_insert is a list of tuples `(shader_type, location, origin, snippet)`.
        to_insert = self._to_insert
        # Find the place where to insert the GLSL snippet.
        # This is "gl_Position = transform(data_var_name);" where
        # data_var_name is typically an attribute.
        vs_regex = re.compile(r'gl_Position = transform\(([\S]+)\);')
        r = vs_regex.search(vertex)
        if not r:
            logger.debug(
                "The vertex shader doesn't contain the transform placeholder: skipping the "
                "transform chain GLSL insertion.")
            return vertex, fragment
        assert r
        logger.log(5, "Found transform placeholder in vertex code: `%s`", r.group(0))

        # Find the GLSL variable with the data (should be a `vec2`).
        var = r.group(1)
        assert var and var in vertex

        # Headers.
        vertex = _get_glsl(
            to_insert, 'vert', 'header', exclude_origins=exclude_origins) + '\n\n' + vertex
        fragment = _get_glsl(
            to_insert, 'frag', 'header', exclude_origins=exclude_origins) + '\n\n' + fragment

        # Get the pre and post transforms.
        vs_insert = _get_glsl(
            to_insert, 'vert', 'before_transforms', exclude_origins=exclude_origins)
        vs_insert += _get_glsl(
            to_insert, 'vert', 'transforms', exclude_origins=exclude_origins)
        vs_insert += _get_glsl(
            to_insert, 'vert', 'after_transforms', exclude_origins=exclude_origins)

        # Insert the GLSL snippet in the vertex shader.
        vertex = vs_regex.sub(indent(vs_insert), vertex)

        # Now, we make the replacements in the fragment shader.
        fs_regex = re.compile(r'(void main\(\)\s*\{)')
        # NOTE: we add the `void main(){` that was removed by the regex.
        fs_insert = '\\1\n' + _get_glsl(
            to_insert, 'frag', 'before_transforms', exclude_origins=exclude_origins)
        fragment = fs_regex.sub(indent(fs_insert), fragment)

        # Replace the transformed variable placeholder by its name.
        vertex = vertex.replace('{{ var }}', var)

        return vertex, fragment

    def __add__(self, inserter):
        """Concatenate two inserters."""
        self._to_insert += inserter._to_insert
        return self


#------------------------------------------------------------------------------
# Base canvas
#------------------------------------------------------------------------------

def get_modifiers(e):
    """Return modifier names from a Qt event."""
    m = e.modifiers()
    return tuple(
        name for name in ('Shift', 'Control', 'Alt', 'Meta') if m & getattr(Qt, name + 'Modifier'))


_BUTTON_MAP = {
    1: 'Left',
    2: 'Right',
    4: 'Middle'
}


_SUPPORTED_KEYS = (
    'Shift',
    'Control',
    'Alt',
    'AltGr',
    'Meta',
    'Left',
    'Up',
    'Right',
    'Down',
    'PageUp',
    'PageDown',
    'Insert',
    'Delete',
    'Home',
    'End',
    'Escape',
    'Backspace',
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
    'Space',
    'Enter',
    'Return',
    'Tab',
)


def mouse_info(e):
    """Extract the position and button of a Qt mouse event."""
    p = e.pos()
    x, y = p.x(), p.y()
    b = e.button()
    return (x, y), _BUTTON_MAP.get(b, None)


def key_info(e):
    """Extract the key of a Qt keyboard event."""
    key = int(e.key())
    if 32 <= key <= 127:
        return chr(key)
    else:
        for name in _SUPPORTED_KEYS:
            if key == getattr(Qt, 'Key_' + name, None):
                return name


class LazyProgram(gloo.Program):
    """Derive from `gloo.Program`.

    Register OpenGL program updates for later evaluation instead of executing them directly.

    This is used when updating visuals in background threads. The actual OpenGL update commands
    should always be sent from the main GUI thread.

    """
    def __init__(self, *args, **kwargs):
        self._update_queue = []
        self._is_lazy = False
        super(LazyProgram, self).__init__(*args, **kwargs)

    def __setitem__(self, name, data):
        # Remove all past items with the current name.
        if self._is_lazy:
            self._update_queue[:] = ((n, d) for (n, d) in self._update_queue if n != name)
            self._update_queue.append((name, data))
        else:
            try:
                super(LazyProgram, self).__setitem__(name, data)
            except IndexError:
                pass


class BaseCanvas(QOpenGLWindow):
    """Base canvas class. Derive from QOpenGLWindow.

    The canvas represents an OpenGL-powered rectangular black window where one can add visuals
    and attach interaction (pan/zoom, lasso) and layout (subplot) compaion objects.

    """

    def __init__(self, *args, **kwargs):
        super(BaseCanvas, self).__init__(*args, **kwargs)
        self.transforms = TransformChain()
        self.inserter = GLSLInserter()
        self.visuals = []
        self._next_paint_callbacks = []
        self._size = (0, 0)
        self._is_lazy = False

        # Events.
        self._attached = []
        self._mouse_press_position = None
        self._mouse_press_button = None
        self._mouse_press_modifiers = None
        self._last_mouse_pos = None
        self._mouse_press_time = 0.
        self._current_key_event = None

        # Default window size.
        self.setGeometry(20, 20, 800, 600)

    def get_size(self):
        """Return the window size in pixels."""
        return self.size().width() or 1, self.size().height() or 1

    def window_to_ndc(self, mouse_pos):
        """Convert a mouse position in pixels into normalized device coordinates, taking into
        account pan and zoom."""
        panzoom = getattr(self, 'panzoom', None)
        ndc = (
            panzoom.window_to_ndc(mouse_pos) if panzoom else
            np.asarray(pixels_to_ndc(mouse_pos, size=self.get_size())))
        return ndc

    # Queue
    # ---------------------------------------------------------------------------------------------

    def set_lazy(self, lazy):
        """When the lazy mode is enabled, all OpenGL calls are deferred. Use with
        multithreading.

        Must be called *after* the visuals have been added, but *before* set_data().

        """
        self._is_lazy = lazy
        for visual in self.visuals:
            visual.visual.program._is_lazy = lazy

    # Visuals
    # ---------------------------------------------------------------------------------------------

    def clear(self):
        """Remove all visuals except those marked `clearable=False`."""
        self.visuals[:] = (v for v in self.visuals if not v.get('clearable', True))
        for v in self.visuals:
            if v.get('clearable', True):  # pragma: no cover
                v.close()
                del v

    def remove(self, *visuals):
        """Remove some visuals objects from the canvas."""
        visuals = [v for v in visuals if v is not None]
        self.visuals[:] = (v for v in self.visuals if v.visual not in visuals)
        for v in visuals:
            logger.log(5, "Remove visual %s.", v)
            v.close()
            del v
        gc.collect()

    def get_visual(self, key):
        """Get a visual from its key."""
        for v in self.visuals:
            if v.get('key', None) == key:
                return v.visual

    def add_visual(self, visual, **kwargs):
        """Add a visual to the canvas and build its OpenGL program using the attached interacts.

        We can't build the visual's program before, because we need the canvas' transforms first.

        Parameters
        ----------

        visual : Visual
        clearable : True
            Whether the visual should be deleted when calling `canvas.clear()`.
        exclude_origins : list-like
            List of interact instances that should not apply to that visual. For example, use to
            add a visual outside of the subplots, or with no support for pan and zoom.
        key : str
            An optional key to identify a visual

        """
        if self.has_visual(visual):
            logger.log(5, "This visual has already been added.")
            return
        visual.canvas = self
        # This is the list of origins (mostly, interacts and layouts) that should be ignored
        # when adding this visual. For example, an AxesVisual would keep the PanZoom interact,
        # but not the Grid layout.
        exclude_origins = kwargs.pop('exclude_origins', ())

        # Retrieve the visual's GLSL inserter.
        inserter = visual.inserter

        # Add the visual's transforms first.
        inserter.add_transform_chain(visual.transforms)

        # Then, add the canvas' transforms.
        inserter.add_transform_chain(self.transforms)
        # Also, add the canvas' inserter. The snippets that should be ignored will be excluded
        # in insert_into_shaders() below.
        inserter += self.inserter

        # Now, we insert the transforms GLSL into the shaders.
        vs, fs = visual.vertex_shader, visual.fragment_shader
        vs, fs = inserter.insert_into_shaders(vs, fs, exclude_origins=exclude_origins)

        # Finally, we create the visual's program.
        visual.program = LazyProgram(vs, fs)
        logger.log(5, "Vertex shader: %s", vs)
        logger.log(5, "Fragment shader: %s", fs)

        # Initialize the size.
        visual.on_resize(self.size().width(), self.size().height())
        # Register the visual in the list of visuals in the canvas.
        self.visuals.append(Bunch(visual=visual, **kwargs))
        emit('visual_added', self, visual)
        return visual

    def has_visual(self, visual):
        """Return whether a visual belongs to the canvas."""
        for v in self.visuals:
            if v.visual == visual:
                return True
        return False

    def iter_update_queue(self):
        """Iterate through all OpenGL program updates called in lazy mode."""
        for v in self.visuals:
            while v.visual.program._update_queue:
                name, data = v.visual.program._update_queue.pop(0)
                yield v.visual.program, name, data

    # OpenGL methods
    # ---------------------------------------------------------------------------------------------

    def on_next_paint(self, f):
        """Register a function to be called at the next frame refresh (in paintGL())."""
        self._next_paint_callbacks.append(f)

    def initializeGL(self):
        """Create the scene."""
        # Enable transparency.
        gl.enable_depth_mask()
        self.update()

    def paintGL(self):
        """Draw all visuals."""
        try:
            gloo.clear()
            size = self.get_size()
            # Flush the queue of next paint callbacks.
            for f in self._next_paint_callbacks:
                f()
            self._next_paint_callbacks.clear()
            # Draw all visuals, clearable first, non clearable last.
            visuals = [v for v in self.visuals if v.get('clearable', True)]
            visuals += [v for v in self.visuals if not v.get('clearable', True)]
            logger.log(5, "Draw %d visuals.", len(visuals))
            for v in visuals:
                visual = v.visual
                if size != self._size:
                    visual.on_resize(*size)
                # Do not draw if there are no vertices.
                if not visual._hidden and visual.n_vertices > 0:
                    logger.log(5, "Draw visual `%s`.", visual)
                    visual.on_draw()
            self._size = size
        except Exception:  # pragma: no cover
            traceback.print_exc()

    # Events
    # ---------------------------------------------------------------------------------------------

    def attach_events(self, obj):
        """Attach an object that has `on_xxx()` methods. These methods are called when internal
        events are raised by the canvas. This is used for mouse and key interactions."""
        self._attached.append(obj)

    def emit(self, name, **kwargs):
        """Raise an internal event and call `on_xxx()` on attached objects."""
        for obj in self._attached:
            f = getattr(obj, 'on_' + name, None)
            if f:
                f(Bunch(kwargs))

    def resizeEvent(self, e):
        """Emit a `resize(width, height)` event when resizing the window."""
        self.emit('resize')
        # Also emit a global resize event.
        emit('resize', self, *self.get_size())

    def _mouse_event(self, name, e):
        """Emit an internal generic mouse event."""
        pos, button = mouse_info(e)
        modifiers = get_modifiers(e)
        key = self._current_key_event[0] if self._current_key_event else None
        self.emit(name, pos=pos, button=button, modifiers=modifiers, key=key)
        return pos, button, modifiers

    def mousePressEvent(self, e):
        """Emit an internal `mouse_press` event."""
        pos, button, modifiers = self._mouse_event('mouse_press', e)
        # Used for dragging.
        self._mouse_press_position = pos
        self._mouse_press_button = button
        self._mouse_press_modifiers = modifiers
        self._mouse_press_time = default_timer()

    def mouseReleaseEvent(self, e):
        """Emit an internal `mouse_release` or `mouse_click` event."""
        self._mouse_event('mouse_release', e)
        # HACK: since there is no mouseClickEvent in Qt, emulate it here.
        if default_timer() - self._mouse_press_time < .25:
            self._mouse_event('mouse_click', e)
        self._mouse_press_position = None
        self._mouse_press_button = None
        self._mouse_press_modifiers = None

    def mouseDoubleClickEvent(self, e):  # pragma: no cover
        """Emit an internal `mouse_double_click` event."""
        self._mouse_event('mouse_double_click', e)

    def mouseMoveEvent(self, e):
        """Emit an internal `mouse_move` event."""
        pos, button = mouse_info(e)
        modifiers = get_modifiers(e)
        self.emit(
            'mouse_move',
            pos=pos,
            last_pos=self._last_mouse_pos,
            modifiers=modifiers,
            mouse_press_modifiers=self._mouse_press_modifiers,
            button=self._mouse_press_button,
            mouse_press_position=self._mouse_press_position)
        self._last_mouse_pos = pos

    def wheelEvent(self, e):  # pragma: no cover
        """Emit an internal `mouse_wheel` event."""
        # NOTE: Qt has no way to simulate wheel events for testing
        delta = e.angleDelta()
        deltay = delta.y() / 120.0
        pos = e.pos().x(), e.pos().y()
        modifiers = get_modifiers(e)
        self.emit('mouse_wheel', pos=pos, delta=deltay, modifiers=modifiers)

    def _key_event(self, name, e):
        """Emit an internal generic key event."""
        key = key_info(e)
        modifiers = get_modifiers(e)
        self.emit(name, key=key, modifiers=modifiers)
        return key, modifiers

    def keyPressEvent(self, e):
        """Emit an internal `key_press` event."""
        key, modifiers = self._key_event('key_press', e)
        self._current_key_event = (key, modifiers)

    def keyReleaseEvent(self, e):
        """Emit an internal `key_release` event."""
        self._key_event('key_release', e)
        self._current_key_event = None

    def event(self, e):  # pragma: no cover
        """Touch event."""
        out = super(BaseCanvas, self).event(e)
        t = e.type()
        # Two-finger pinch.
        if (t == QEvent.TouchBegin):
            self.emit('pinch_begin')
        elif (t == QEvent.TouchEnd):
            self.emit('pinch_end')
        elif (t == QEvent.Gesture):
            gesture = e.gesture(Qt.PinchGesture)
            if gesture:
                (x, y) = gesture.centerPoint().x(), gesture.centerPoint().y()
                scale = gesture.scaleFactor()
                last_scale = gesture.lastScaleFactor()
                rotation = gesture.rotationAngle()
                self.emit(
                    'pinch', pos=(x, y),
                    scale=scale, last_scale=last_scale, rotation=rotation)
        # General touch event.
        elif (t == QEvent.TouchUpdate):
            points = e.touchPoints()
            # These variables are lists of (x, y) coordinates.
            pos, last_pos = zip(*[
                ((p.pos().x(), p.pos.y()), (p.lastPos().x(), p.lastPos.y()))
                for p in points])
            self.emit('touch', pos=pos, last_pos=last_pos)
        return out

    def update(self):
        """Update the OpenGL canvas."""
        if not self._is_lazy:
            super(BaseCanvas, self).update()


#------------------------------------------------------------------------------
# Base layout
#------------------------------------------------------------------------------

class BaseLayout(object):
    """Implement global transforms on a canvas, like subplots."""
    canvas = None
    box_var = None
    n_dims = 1
    active_box = 0

    def __init__(self, box_var=None):
        self.box_var = box_var or 'a_box_index'

    def attach(self, canvas):
        """Attach this layout to a canvas."""
        self.canvas = canvas
        canvas.layout = self
        canvas.attach_events(self)

        @connect(sender=canvas)
        def on_visual_set_data(sender, visual):
            if canvas.has_visual(visual):
                self.update_visual(visual)

    def map(self, arr, box=None):
        """Direct transformation from data to NDC coordinates."""
        raise NotImplementedError()

    def imap(self, arr, box=None):
        """Inverse transformation from NDC to data coordinates."""
        raise NotImplementedError()

    def get_closest_box(self, ndc):
        """Override to return the box closest to a given position in NDC."""
        raise NotImplementedError()

    def box_map(self, mouse_pos):
        """Get the box and local NDC coordinates from mouse position."""
        if not self.canvas:
            return
        ndc = self.canvas.window_to_ndc(mouse_pos)
        box = self.get_closest_box(ndc)
        self.active_box = box
        # From NDC to data coordinates, in the given box.
        return box, self.imap(ndc, box)

    def update_visual(self, visual):
        """Called whenever visual.set_data() is called. Set a_box_index in here."""
        if (visual.n_vertices > 0 and
                self.box_var in visual.program and
                ((visual.program[self.box_var] is None) or
                 (visual.program[self.box_var].shape[0] != visual.n_vertices))):
            logger.log(5, "Set %s(%d) for %s" % (self.box_var, visual.n_vertices, visual))
            visual.program[self.box_var] = _get_array(
                self.active_box, (visual.n_vertices, self.n_dims)).astype(np.float32)

    def update(self):
        """Update all visuals in the attached canvas."""
        if not self.canvas:
            return
        for v in self.canvas.visuals:
            self.update_visual(v.visual)
        self.canvas.update()
