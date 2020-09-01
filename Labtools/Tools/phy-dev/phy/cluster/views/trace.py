# -*- coding: utf-8 -*-

"""Trace view."""


# -----------------------------------------------------------------------------
# Imports
# -----------------------------------------------------------------------------

import logging

import numpy as np

from phylib.utils import Bunch, emit
from phylib.utils.color import selected_cluster_color
from phy.plot.transform import NDC, Range, _fix_coordinate_in_visual
from phy.plot.visuals import PlotVisual, UniformPlotVisual, TextVisual
from .base import ManualClusteringView, ScalingMixin

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Trace view
# -----------------------------------------------------------------------------

def select_traces(traces, interval, sample_rate=None):
    """Load traces in an interval (in seconds)."""
    start, end = interval
    i, j = round(sample_rate * start), round(sample_rate * end)
    i, j = int(i), int(j)
    traces = traces[i:j, :]
    traces = traces - np.median(traces, axis=0)
    return traces


def _iter_spike_waveforms(
        interval=None, traces_interval=None, model=None, supervisor=None,
        n_samples_waveforms=None, get_best_channels=None, show_all_spikes=False,
        color_selector=None,):
    """Iterate through the spike waveforms belonging in the current trace view."""

    m = model
    p = supervisor
    cs = color_selector
    sr = m.sample_rate
    a, b = m.spike_times.searchsorted(interval)
    s0, s1 = int(round(interval[0] * sr)), int(round(interval[1] * sr))
    ns = n_samples_waveforms
    k = ns // 2
    for i in range(a, b):
        t = m.spike_times[i]
        c = m.spike_clusters[i]
        # Skip non-selected spikes if requested.
        if (not show_all_spikes and c not in supervisor.selected):
            continue
        # cg = p.cluster_meta.get('group', c)
        channel_ids = get_best_channels(c)
        s = int(round(t * sr)) - s0
        # Skip partial spikes.
        if s - k < 0 or s + k >= (s1 - s0):  # pragma: no cover
            continue
        # Choose cluster color.
        if c in p.selected:
            i = p.selected.index(c)
            color = selected_cluster_color(i, alpha=1)
        else:  # pragma: no cover
            color = cs.get(c, alpha=1)
        # Extract the waveform.
        wave = Bunch(
            data=traces_interval[s - k:s + ns - k, channel_ids],
            channel_ids=channel_ids,
            start_time=(s + s0 - k) / sr,
            color=color,
            spike_id=i,
            spike_time=t,
            spike_cluster=c,
        )
        assert wave.data.shape == (ns, len(channel_ids))
        yield wave


class TraceView(ScalingMixin, ManualClusteringView):
    """This view shows the raw traces along with spike waveforms.

    Constructor
    -----------

    traces : function
        Maps a time interval `(t0, t1)` to a `Bunch(data, color, waveforms)` where
        * `data` is an `(n_samples, n_channels)` array
        * `waveforms` is a list of bunchs with the following attributes:
            * `data`
            * `color`
            * `channel_ids`
            * `start_time`
            * `spike_id`
            * `spike_cluster`

    spike_times : function
        Teturns the list of relevant spike times.
    sample_rate : float
    duration : float
    n_channels : int
    channel_vertical_order : array-like
        Permutation of the channels. This 1D array gives the channel id of all channels from
        top to bottom (or conversely, depending on `origin=top|bottom`).
    channel_labels : list
        Labels of all shown channels. By default, this is just the channel ids.

    """
    _default_position = 'left'
    auto_update = True
    auto_scale = True
    interval_duration = .25  # default duration of the interval
    shift_amount = .1
    scaling_coeff_x = 1.25
    trace_quantile = .01  # quantile for auto-scaling
    default_trace_color = (.5, .5, .5, 1)
    default_shortcuts = {
        'change_trace_size': 'ctrl+wheel',
        'decrease': 'alt+down',
        'increase': 'alt+up',
        'go_left': 'alt+left',
        'go_right': 'alt+right',
        'go_to_start': 'alt+home',
        'go_to_end': 'alt+end',
        'go_to': 'alt+t',
        'go_to_next_spike': 'alt+pgdown',
        'go_to_previous_spike': 'alt+pgup',
        'narrow': 'alt++',
        'select_spike': 'ctrl+click',
        'switch_origin': 'alt+o',
        'toggle_highlighted_spikes': 'alt+s',
        'toggle_show_labels': 'alt+l',
        'widen': 'alt+-',
    }
    default_snippets = {
        'go_to': 'tg',
        'shift': 'ts',
    }

    def __init__(
            self, traces=None, sample_rate=None, spike_times=None, duration=None, n_channels=None,
            channel_vertical_order=None, channel_labels=None, **kwargs):

        self.do_show_labels = True
        self.show_all_spikes = False
        self._scaling = 1.

        self.get_spike_times = spike_times

        # Sample rate.
        assert sample_rate > 0
        self.sample_rate = float(sample_rate)
        self.dt = 1. / self.sample_rate

        # Traces and spikes.
        assert hasattr(traces, '__call__')
        self.traces = traces
        self.waveforms = None

        assert duration >= 0
        self.duration = duration

        assert n_channels >= 0
        self.n_channels = n_channels

        # Channel permutation.
        self._channel_perm = (
            np.arange(n_channels) if channel_vertical_order is None else channel_vertical_order)
        assert self._channel_perm.shape == (n_channels,)
        self._channel_perm = np.argsort(self._channel_perm)

        # Channel labels.
        self.channel_labels = (
            channel_labels if channel_labels is not None else
            ['%d' % ch for ch in range(n_channels)])
        assert len(self.channel_labels) == n_channels

        # Box and probe scaling.
        self._origin = None

        # Initialize the view.
        super(TraceView, self).__init__(**kwargs)
        self.state_attrs += ('origin', 'do_show_labels', 'show_all_spikes', 'auto_scale')
        self.local_state_attrs += ('interval', 'scaling',)

        self.canvas.set_layout('stacked', origin=self.origin, n_plots=self.n_channels)
        self.canvas.enable_axes(show_y=False)

        # Visuals.
        self.trace_visual = UniformPlotVisual()
        self.canvas.add_visual(self.trace_visual)

        self.waveform_visual = PlotVisual()
        self.canvas.add_visual(self.waveform_visual)

        self.text_visual = TextVisual()
        _fix_coordinate_in_visual(self.text_visual, 'x')
        self.canvas.add_visual(self.text_visual)

        # Make a copy of the initial box pos and size. We'll apply the scaling
        # to these quantities.
        self.box_size = np.array(self.canvas.stacked.box_size)

        # Initial interval.
        self._interval = None
        self.go_to(duration / 2.)

        self._waveform_times = []

    @property
    def stacked(self):
        return self.canvas.stacked

    def _permute_channels(self, x, inv=False):
        cp = self._channel_perm
        cp = np.argsort(cp)
        return cp[x]

    # Internal methods
    # -------------------------------------------------------------------------

    def _plot_traces(self, traces, color=None):
        traces = traces.T
        n_samples = traces.shape[1]
        n_ch = self.n_channels
        assert traces.shape == (n_ch, n_samples)
        color = color or self.default_trace_color

        t = self._interval[0] + np.arange(n_samples) * self.dt
        t = np.tile(t, (n_ch, 1))

        box_index = self._permute_channels(np.arange(n_ch))
        box_index = np.repeat(box_index[:, np.newaxis], n_samples, axis=1)

        assert t.shape == (n_ch, n_samples)
        assert traces.shape == (n_ch, n_samples)
        assert box_index.shape == (n_ch, n_samples)

        self.trace_visual.color = color
        self.canvas.update_visual(
            self.trace_visual,
            t, traces,
            data_bounds=self.data_bounds,
            box_index=box_index.ravel(),
        )

    def _plot_spike(self, bunch):
        # The spike time corresponds to the first sample of the waveform.
        n_samples, n_channels = bunch.data.shape
        assert len(bunch.channel_ids) == n_channels

        # Generate the x coordinates of the waveform.
        t = bunch.start_time + self.dt * np.arange(n_samples)
        t = np.tile(t, (n_channels, 1))  # (n_unmasked_channels, n_samples)

        # The box index depends on the channel.
        box_index = self._permute_channels(bunch.channel_ids)
        box_index = np.repeat(box_index[:, np.newaxis], n_samples, axis=0)
        self.waveform_visual.add_batch_data(
            box_index=box_index,
            x=t, y=bunch.data.T, color=bunch.color,
            data_bounds=self.data_bounds,
        )

    def _plot_labels(self, traces):
        self.text_visual.reset_batch()
        for ch in range(self.n_channels):
            bi = self._permute_channels(ch)
            ch_label = self.channel_labels[ch]
            self.text_visual.add_batch_data(
                pos=[self.data_bounds[0], 0],
                text=ch_label,
                anchor=[+1., 0],
                data_bounds=self.data_bounds,
                box_index=bi,
            )
        self.canvas.update_visual(self.text_visual)

    # Public methods
    # -------------------------------------------------------------------------

    def _restrict_interval(self, interval):
        start, end = interval
        # Round the times to full samples to avoid subsampling shifts
        # in the traces.
        start = int(round(start * self.sample_rate)) / self.sample_rate
        end = int(round(end * self.sample_rate)) / self.sample_rate
        # Restrict the interval to the boundaries of the traces.
        if start < 0:
            end += (-start)
            start = 0
        elif end >= self.duration:
            start -= (end - self.duration)
            end = self.duration
        start = np.clip(start, 0, end)
        end = np.clip(end, start, self.duration)
        assert 0 <= start < end <= self.duration
        return start, end

    def set_interval(self, interval=None, change_status=True):
        """Display the traces and spikes in a given interval."""
        if interval is None:
            interval = self._interval
        interval = self._restrict_interval(interval)

        # Load the traces.
        traces = self.traces(interval)
        self.waveforms = traces.get('waveforms', [])

        if interval != self._interval:
            logger.debug("Redraw the entire trace view.")
            self._interval = interval
            start, end = interval

            # Set the status message.
            if change_status:
                self.set_status('Interval: {:.3f} s - {:.3f} s'.format(start, end))

            # Find the data bounds.
            if self.auto_scale or getattr(self, 'data_bounds', NDC) == NDC:
                ymin = np.quantile(traces.data, self.trace_quantile)
                ymax = np.quantile(traces.data, 1. - self.trace_quantile)
            else:
                ymin, ymax = self.data_bounds[1], self.data_bounds[3]
            self.data_bounds = (start, ymin, end, ymax)

            # Used for spike click.
            self._waveform_times = []

            # Plot the traces.
            self._plot_traces(
                traces.data, color=traces.get('color', None))

            # Plot the labels.
            if self.do_show_labels:
                self._plot_labels(traces.data)

        # Plot the waveforms.
        self.plot()

    def on_select(self, cluster_ids=None, **kwargs):
        self.cluster_ids = cluster_ids
        if not cluster_ids:
            return
        # Make sure we call again self.traces() when the cluster selection changes.
        self.set_interval()

    def plot(self, **kwargs):
        """Plot the waveforms."""
        waveforms = self.waveforms
        assert isinstance(waveforms, list)
        if waveforms:
            self.waveform_visual.show()
            self.waveform_visual.reset_batch()
            for w in waveforms:
                self._plot_spike(w)
                self._waveform_times.append(
                    (w.start_time, w.spike_id, w.spike_cluster, w.get('channel_ids', None)))
            self.canvas.update_visual(self.waveform_visual)
        else:  # pragma: no cover
            self.waveform_visual.hide()

        self._update_axes()
        self.canvas.update()

    def attach(self, gui):
        """Attach the view to the GUI."""
        super(TraceView, self).attach(gui)

        self.actions.add(self.toggle_show_labels, checkable=True, checked=self.do_show_labels)
        self.actions.add(
            self.toggle_highlighted_spikes, checkable=True, checked=self.show_all_spikes)
        self.actions.add(self.toggle_auto_scale, checkable=True, checked=self.auto_scale)
        self.actions.add(self.switch_origin)
        self.actions.separator()

        self.actions.add(
            self.go_to, prompt=True, prompt_default=lambda: str(self.time))
        self.actions.separator()

        self.actions.add(self.go_to_start)
        self.actions.add(self.go_to_end)
        self.actions.separator()

        self.actions.add(self.shift, prompt=True)
        self.actions.add(self.go_right)
        self.actions.add(self.go_left)
        self.actions.separator()

        self.actions.add(self.widen)
        self.actions.add(self.narrow)
        self.actions.separator()

        self.actions.add(self.go_to_next_spike)
        self.actions.add(self.go_to_previous_spike)
        self.actions.separator()

        self.set_interval()

    # Origin
    # -------------------------------------------------------------------------

    @property
    def origin(self):
        """Whether to show the channels from top to bottom (`top` option, the default), or from
        bottom to top (`bottom`)."""
        return self._origin

    @origin.setter
    def origin(self, value):
        self._origin = value
        if self.canvas.layout:
            self.canvas.layout.origin = value

    def switch_origin(self):
        """Switch between top and bottom origin for the channels."""
        self.origin = 'top' if self._origin in ('bottom', None) else 'bottom'

    # Navigation
    # -------------------------------------------------------------------------

    @property
    def time(self):
        """Time at the center of the window."""
        return sum(self._interval) * .5

    @property
    def interval(self):
        """Interval as `(tmin, tmax)`."""
        return self._interval

    @interval.setter
    def interval(self, value):
        self.set_interval(value)

    @property
    def half_duration(self):
        """Half of the duration of the current interval."""
        if self._interval is not None:
            a, b = self._interval
            return (b - a) * .5
        else:
            return self.interval_duration * .5

    def go_to(self, time):
        """Go to a specific time (in seconds)."""
        half_dur = self.half_duration
        self.set_interval((time - half_dur, time + half_dur))

    def shift(self, delay):
        """Shift the interval by a given delay (in seconds)."""
        self.go_to(self.time + delay)

    def go_to_start(self):
        """Go to the start of the recording."""
        self.go_to(0)

    def go_to_end(self):
        """Go to end of the recording."""
        self.go_to(self.duration)

    def go_right(self):
        """Go to right."""
        start, end = self._interval
        delay = (end - start) * .1
        self.shift(delay)

    def go_left(self):
        """Go to left."""
        start, end = self._interval
        delay = (end - start) * .1
        self.shift(-delay)

    def _jump_to_spike(self, delta=+1):
        """Jump to next or previous spike from the selected clusters."""
        spike_times = self.get_spike_times()
        if spike_times is not None and len(spike_times):
            ind = np.searchsorted(spike_times, self.time)
            n = len(spike_times)
            self.go_to(spike_times[(ind + delta) % n])

    def go_to_next_spike(self, ):
        """Jump to the next spike from the first selected cluster."""
        self._jump_to_spike(+1)

    def go_to_previous_spike(self, ):
        """Jump to the previous spike from the first selected cluster."""
        self._jump_to_spike(-1)

    def toggle_highlighted_spikes(self, checked):
        """Toggle between showing all spikes or selected spikes."""
        self.show_all_spikes = checked
        self.set_interval()

    def widen(self):
        """Increase the interval size."""
        t, h = self.time, self.half_duration
        h *= self.scaling_coeff_x
        self.set_interval((t - h, t + h))

    def narrow(self):
        """Decrease the interval size."""
        t, h = self.time, self.half_duration
        h /= self.scaling_coeff_x
        self.set_interval((t - h, t + h))

    # Misc
    # -------------------------------------------------------------------------

    def toggle_show_labels(self, checked):
        """Toggle the display of the channel ids."""
        logger.debug("Set show labels to %s.", checked)
        self.do_show_labels = checked
        self.set_interval()

    def toggle_auto_scale(self, checked):
        """Toggle automatic scaling of the traces."""
        logger.debug("Set auto scale to %s.", checked)
        self.auto_scale = checked

    # Scaling
    # -------------------------------------------------------------------------

    def _apply_scaling(self):
        self.canvas.layout.scaling = (self.canvas.layout.scaling[0], self._scaling)

    @property
    def scaling(self):
        """Scaling of the channel boxes."""
        return self._scaling

    @scaling.setter
    def scaling(self, value):
        self._scaling = value
        self._apply_scaling()

    def _get_scaling_value(self):
        return self.scaling

    def _set_scaling_value(self, value):
        self.scaling = value

    # Spike selection
    # -------------------------------------------------------------------------

    def on_mouse_click(self, e):
        """Select a cluster by clicking on a spike."""
        if 'Control' in e.modifiers:
            # Get mouse position in NDC.
            box_id, _ = self.canvas.stacked.box_map(e.pos)
            channel_id = self._permute_channels(box_id, inv=True)
            # Find the spike and cluster closest to the mouse.
            db = self.data_bounds
            # Get the information about the displayed spikes.
            wt = [(t, s, c, ch) for t, s, c, ch in self._waveform_times if channel_id in ch]
            if not wt:
                return
            # Get the time coordinate of the mouse position.
            mouse_pos = self.canvas.panzoom.window_to_ndc(e.pos)
            mouse_time = Range(NDC, db).apply(mouse_pos)[0][0]
            # Get the closest spike id.
            times, spike_ids, spike_clusters, channel_ids = zip(*wt)
            i = np.argmin(np.abs(np.array(times) - mouse_time))
            # Raise the spike_click event.
            spike_id = spike_ids[i]
            cluster_id = spike_clusters[i]
            emit('spike_click', self, channel_id=channel_id,
                 spike_id=spike_id, cluster_id=cluster_id)
