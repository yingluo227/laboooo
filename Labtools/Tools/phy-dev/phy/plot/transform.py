# -*- coding: utf-8 -*-

"""Transforms."""


#------------------------------------------------------------------------------
# Imports
#------------------------------------------------------------------------------

import logging
from textwrap import dedent

import numpy as np

from phylib.utils.geometry import range_transform

logger = logging.getLogger(__name__)


#------------------------------------------------------------------------------
# Utils
#------------------------------------------------------------------------------

def _wrap_apply(f):
    """Validate the input and output of transform apply functions."""
    def wrapped(arr, **kwargs):
        if arr is None or not len(arr):
            return arr
        arr = np.atleast_2d(arr)
        assert arr.ndim == 2
        assert arr.dtype in (np.float32, np.float64)
        out = f(arr, **kwargs)
        assert out.dtype == arr.dtype
        out = np.atleast_2d(out)
        assert out.ndim == 2
        assert out.shape[1] == arr.shape[1]
        return out
    return wrapped


def _wrap_glsl(f):
    """Validate the output of GLSL functions."""
    def wrapped(var, **kwargs):
        out = f(var, **kwargs)
        out = dedent(out).strip()
        return out
    return wrapped


def _glslify(r):
    """Transform a string or a n-tuple to a valid GLSL expression."""
    if isinstance(r, str):
        return r
    else:
        assert 2 <= len(r) <= 4
        return 'vec{}({})'.format(len(r), ', '.join(map(str, r)))


def _minus(value):
    if isinstance(value, np.ndarray):
        return -value
    else:
        assert len(value) == 2
        return -value[0], -value[1]


def _inverse(value):
    if isinstance(value, np.ndarray):
        return 1. / value
    elif hasattr(value, '__len__'):
        assert len(value) == 2
        return 1. / value[0], 1. / value[1]
    else:
        return 1. / value


def _normalize(arr, m, M):
    d = float(M - m)
    if abs(d) < 1e-9:
        return arr
    b = 2. / d
    a = -1 - 2. * m / d
    arr *= b
    arr += a
    return arr


def _fix_coordinate_in_visual(visual, coord):
    """Insert GLSL code to fix the position on the x or y coordinate."""
    assert coord in ('x', 'y')
    visual.inserter.insert_vert(
        'gl_Position.{coord} = pos_orig.{coord};'.format(coord=coord),
        'after_transforms')


def subplot_bounds(shape=None, index=None):
    """Get the data bounds of a subplot."""
    i, j = index
    n_rows, n_cols = shape

    assert 0 <= i <= n_rows - 1
    assert 0 <= j <= n_cols - 1

    width = 2.0 / n_cols
    height = 2.0 / n_rows

    x = -1.0 + j * width
    y = +1.0 - (i + 1) * height

    return [x, y, x + width, y + height]


def subplot_bounds_glsl(shape=None, index=None):
    """Get the data bounds in GLSL of a subplot."""
    x0 = '-1.0 + 2.0 * {i}.y / {s}.y'.format(s=shape, i=index)
    y0 = '+1.0 - 2.0 * ({i}.x + 1) / {s}.x'.format(s=shape, i=index)
    x1 = '-1.0 + 2.0 * ({i}.y + 1) / {s}.y'.format(s=shape, i=index)
    y1 = '+1.0 - 2.0 * ({i}.x) / {s}.x'.format(s=shape, i=index)

    return 'vec4(\n{x0}, \n{y0}, \n{x1}, \n{y1})'.format(x0=x0, y0=y0, x1=x1, y1=y1)


def extend_bounds(bounds_list):
    """Return a single data bounds 4-tuple from a list of data bounds."""
    bounds = np.array(bounds_list)
    xmins, ymins = bounds[:, :2].min(axis=0)
    xmaxs, ymaxs = bounds[:, 2:].max(axis=0)
    xmin, ymin, xmax, ymax = xmins.min(), ymins.min(), xmaxs.max(), ymaxs.max()
    # Avoid degenerate bounds.
    if xmin == xmax:
        xmin, xmax = -1, 1
    if ymin == ymax:
        ymin, ymax = -1, 1
    return (xmin, ymin, xmax, ymax)


def pixels_to_ndc(pos, size=None):
    """Convert from pixels to normalized device coordinates (in [-1, 1])."""
    pos = np.asarray(pos, dtype=np.float64)
    size = np.asarray(size, dtype=np.float64)
    pos = pos / (size / 2.) - 1
    # Flip y, because the origin in pixels is at the top left corner of the
    # window.
    pos[1] = -pos[1]
    return pos


"""Bounds in Normalized Device Coordinates (NDC)."""
NDC = (-1.0, -1.0, +1.0, +1.0)


#------------------------------------------------------------------------------
# Transforms
#------------------------------------------------------------------------------

class BaseTransform(object):
    """Base class for all transforms."""
    def __init__(self, value=None):
        self.value = value
        self.apply = _wrap_apply(self.apply)
        self.glsl = _wrap_glsl(self.glsl)

    def apply(self, arr):
        """Apply the transform to an (n, 2) array."""
        raise NotImplementedError()

    def glsl(self, var):
        """Return the GLSL code for the transform."""
        raise NotImplementedError()

    def inverse(self):
        """Return a Transform instance for the inverse transform."""
        raise NotImplementedError()

    def __repr__(self):
        return '<%s (%s)>' % (self.__class__.__name__, self.value)


class Translate(BaseTransform):
    """Translation transform.

    Constructor
    -----------
    value : 2-tuple
        Coordinates of the translation.

    """

    def apply(self, arr, value=None):
        """Apply a translation to a NumPy array."""
        assert isinstance(arr, np.ndarray)
        value = value if value is not None else self.value
        return arr + np.asarray(value)

    def glsl(self, var):
        """Return a GLSL snippet that applies the translation to a given GLSL variable name."""
        assert var
        return '''
        // Translate transform.
        {var} = {var} + {translate};
        '''.format(var=var, translate=self.value)

    def inverse(self):
        """Return the inverse Translate instance."""
        if isinstance(self.value, str):
            return Translate('-' + self.value)
        else:
            return Translate(_minus(self.value))


class Scale(BaseTransform):
    """Scaling transform.

    Constructor
    -----------
    value : 2-tuple
        Coordinates of the scaling.

    """

    def apply(self, arr, value=None):
        """Apply a scaling to a NumPy array."""
        value = value if value is not None else self.value
        if isinstance(value, str):
            value = 1
        return arr * np.asarray(value)

    def glsl(self, var):
        """Return a GLSL snippet that applies the scaling to a given GLSL variable name."""
        assert var
        return '''
        // Scale transform.
        {var} = {var} * {scale};
        '''.format(var=var, scale=self.value)

    def inverse(self):
        """Return the inverse Scale instance."""
        if isinstance(self.value, str):
            return Scale('1.0 / ' + self.value)
        else:
            return Scale(_inverse(self.value))


class Rotate(BaseTransform):
    """Rotation transform, either +90° CW (default) or +90° CCW.

    Constructor
    -----------
    value : str
        Either `cw` (default) or `ccw`.

    """
    def __init__(self, value=None):
        value = value or 'cw'
        assert value in ('cw', 'ccw')
        super(Rotate, self).__init__(value=value)

    def apply(self, arr, value=None):
        """Apply a rotation to a NumPy array."""
        assert isinstance(arr, np.ndarray)
        value = value if value is not None else self.value
        value = value or 'cw'  # clockwise is the default
        assert value in ('cw', 'ccw')
        assert arr.ndim == 2
        assert arr.shape[1] == 2
        x, y = arr.T
        if value == 'ccw':
            return np.c_[-y, x]
        else:
            return np.c_[y, -x]

    def glsl(self, var):
        """Return a GLSL snippet that applies the rotation to a given GLSL variable name."""
        assert var
        assert self.value in ('cw', 'ccw')
        m = '' if self.value == 'ccw' else '-'
        return '''
        {var} = {m}vec2(-{var}.y, {var}.x);  // Rotation transform.
        '''.format(var=var, m=m)

    def inverse(self):
        """Return the inverse Rotate instance."""
        assert self.value in ('cw', 'ccw')
        if self.value == 'ccw':
            return Rotate('cw')
        else:
            return Rotate('ccw')


class Range(BaseTransform):
    """Linear transform from a source rectangle to a target rectangle.

    Constructor
    -----------

    from_bounds : 4-tuple
        Bounds of the source rectangle.
    to_bounds : 4-tuple
        Bounds of the target rectangle.

    """

    def __init__(self, from_bounds=None, to_bounds=None):
        super(Range, self).__init__()
        self.from_bounds = from_bounds if from_bounds is not None else NDC
        self.to_bounds = to_bounds if to_bounds is not None else NDC

    def apply(self, arr, from_bounds=None, to_bounds=None):
        """Apply the transform to a NumPy array."""
        from_bounds = np.asarray(
            from_bounds if from_bounds is not None else self.from_bounds, dtype=np.float64)
        to_bounds = np.asarray(
            to_bounds if to_bounds is not None else self.to_bounds, dtype=np.float64)
        return range_transform(from_bounds, to_bounds, arr)

    def glsl(self, var):
        """Return a GLSL snippet that applies the transform to a given GLSL variable name."""
        assert var

        from_bounds = _glslify(self.from_bounds)
        to_bounds = _glslify(self.to_bounds)

        return '''
        // Range transform.
        vec2 fxy = {f}.xy;
        vec2 fzw = {f}.zw;
        vec2 txy = {t}.xy;
        vec2 tzw = {t}.zw;
        {var} = ({var} - fxy);
        {var} = {var} * (tzw - txy);
        {var} = {var} / (fzw - fxy);
        {var} = {var} + txy;
        '''.format(var=var, f=from_bounds, t=to_bounds)

    def inverse(self):
        """Return the inverse Range instance."""
        return Range(from_bounds=self.to_bounds, to_bounds=self.from_bounds)


class Clip(BaseTransform):
    """Transform that discards data outside a given rectangle."""

    def __init__(self, bounds=None):
        super(Clip, self).__init__()
        self.bounds = bounds or NDC

    def apply(self, arr, bounds=None):
        """Apply the clipping to a NumPy array."""
        bounds = bounds if bounds is not None else self.bounds
        index = ((arr[:, 0] >= bounds[0]) &
                 (arr[:, 1] >= bounds[1]) &
                 (arr[:, 0] <= bounds[2]) &
                 (arr[:, 1] <= bounds[3]))
        return arr[index, ...]

    def glsl(self, var):
        """Return a GLSL snippet that applies the clipping to a given GLSL variable name,
        in the fragment shader."""
        assert var
        bounds = _glslify(self.bounds)

        return """
        // Clip transform.
        if (({var}.x < {bounds}.x) ||
            ({var}.y < {bounds}.y) ||
            ({var}.x > {bounds}.z) ||
            ({var}.y > {bounds}.w)) {{
            discard;
        }}
        """.format(bounds=bounds, var=var)

    def inverse(self):
        """Return the same instance (the inverse has no sense for a Clip transform)."""
        return self


class Subplot(Range):
    """Transform to a grid subplot rectangle.

    Constructor
    -----------

    shape : 2-tuple
        Number of rows and columns in the grid.
    index : 2-tuple
        Row and column index of the subplot to transform into.

    """

    def __init__(self, shape, index=None):
        super(Subplot, self).__init__()
        self.shape = shape
        self.index = index
        self.from_bounds = NDC
        if isinstance(self.shape, tuple) and isinstance(self.index, tuple):
            self.to_bounds = subplot_bounds(shape=self.shape, index=self.index)
        elif (isinstance(self.shape, str) and
                isinstance(self.index, str)):
            self.to_bounds = subplot_bounds_glsl(shape=self.shape, index=self.index)


#------------------------------------------------------------------------------
# Transform chains
#------------------------------------------------------------------------------

class TransformChain(object):
    """A linear sequence of transforms that happen on the CPU and GPU."""
    def __init__(self):
        self.transformed_var_name = None
        self._transforms = []  # list of tuples (cpu|gpu, transform, origin)

    @property
    def cpu_transforms(self):
        """List of CPU transforms."""
        return [t for (where, t, origin) in self._transforms if where == 'cpu']

    @property
    def gpu_transforms(self):
        """List of GPU transforms."""
        return [t for (where, t, origin) in self._transforms if where == 'gpu']

    def add_on_cpu(self, transforms, origin=None):
        """Add some transforms on the CPU."""
        if not isinstance(transforms, list):
            transforms = [transforms]
        self._transforms.extend([('cpu', t, origin) for t in transforms])
        return self

    def add_on_gpu(self, transforms, origin=None):
        """Add some transforms on the GPU."""
        if not isinstance(transforms, list):
            transforms = [transforms]
        self._transforms.extend([('gpu', t, origin) for t in transforms])
        return self

    def get(self, class_name):
        """Get a transform in the chain from its name."""
        for where, transform, origin in self._transforms:
            if transform.__class__.__name__ == class_name:
                return transform

    def apply(self, arr):
        """Apply all CPU transforms on an array."""
        for t in self.cpu_transforms:
            arr = t.apply(arr)
        return arr

    def inverse(self):
        """Return the inverse chain of transforms."""
        inv_transforms = [
            (where, transform.inverse(), origin)
            for (where, transform, origin) in self._transforms[::-1]]
        inv = TransformChain()
        inv._transforms = inv_transforms
        return inv

    def __add__(self, tc):
        """Concatenate multiple transform chains."""
        assert isinstance(tc, TransformChain)
        assert tc.transformed_var_name == self.transformed_var_name
        self._transforms.extend(tc._transforms)
        return self

    def __repr__(self):
        return 'CPU: %s ; GPU: %s' % (self.cpu_transforms, self.gpu_transforms)
