# -*- coding: utf-8 -*-

"""Test views."""

#------------------------------------------------------------------------------
# Imports
#------------------------------------------------------------------------------

import numpy as np
from numpy.testing import assert_allclose as ac

from phylib.io.mock import artificial_traces, artificial_spike_clusters
from phylib.utils import Bunch, connect
from phylib.utils.color import ClusterColorSelector
from phy.plot.tests import mouse_click

from ..trace import TraceView, select_traces, _iter_spike_waveforms
from . import _stop_and_close


#------------------------------------------------------------------------------
# Test trace view
#------------------------------------------------------------------------------

def test_trace_view_0():
    nc = 5
    ns = 20
    sr = 2000.
    ch = list(range(nc))
    duration = 1.
    st = np.linspace(0.1, .9, ns)
    sc = artificial_spike_clusters(ns, nc)
    traces = 10 * artificial_traces(int(round(duration * sr)), nc)
    cs = ClusterColorSelector(cluster_ids=list(range(nc)))

    m = Bunch(spike_times=st, spike_clusters=sc, sample_rate=sr)
    s = Bunch(cluster_meta={}, selected=[0])

    for w in _iter_spike_waveforms(
            interval=[0., 1.],
            traces_interval=traces,
            model=m,
            supervisor=s,
            n_samples_waveforms=ns,
            show_all_spikes=True,
            get_best_channels=lambda cluster_id: ch,
            color_selector=cs):
        assert w


def test_trace_view_1(qtbot, tempdir, gui):
    nc = 5
    ns = 20
    sr = 2000.
    duration = 1.
    st = np.linspace(0.1, .9, ns)
    sc = artificial_spike_clusters(ns, nc)
    traces = 10 * artificial_traces(int(round(duration * sr)), nc)
    cs = ClusterColorSelector(cluster_ids=list(range(nc)))

    def get_traces(interval):
        out = Bunch(data=select_traces(traces, interval, sample_rate=sr),
                    color=(.75, .75, .75, 1),
                    )
        a, b = st.searchsorted(interval)
        out.waveforms = []
        k = 20
        for i in range(a, b):
            t = st[i]
            c = sc[i]
            s = int(round(t * sr))
            d = Bunch(data=traces[s - k:s + k, :],
                      start_time=(s - k) / sr,
                      color=cs.get(c, alpha=.5),
                      channel_ids=np.arange(5),
                      spike_id=i,
                      spike_cluster=c,
                      )
            out.waveforms.append(d)
        return out

    def get_spike_times():
        return st

    v = TraceView(
        traces=get_traces,
        spike_times=get_spike_times,
        n_channels=nc,
        sample_rate=sr,
        duration=duration,
        channel_vertical_order=np.arange(nc)[::-1],
    )
    v.show()
    qtbot.waitForWindowShown(v.canvas)
    v.attach(gui)

    v.on_select(cluster_ids=[])
    v.on_select(cluster_ids=[0])
    v.on_select(cluster_ids=[0, 2, 3])
    v.on_select(cluster_ids=[0, 2])

    ac(v.stacked.box_size, (1., .19), atol=1e-3)
    v.set_interval((.375, .625))
    assert v.time == .5
    qtbot.wait(1)

    v.go_to(.25)
    assert v.time == .25
    qtbot.wait(1)

    v.go_to(-.5)
    assert v.time == .125
    qtbot.wait(1)

    v.go_left()
    assert v.time == .125
    qtbot.wait(1)

    v.go_right()
    ac(v.time, .150)
    qtbot.wait(1)

    v.go_to_next_spike()
    qtbot.wait(1)

    v.go_to_previous_spike()
    qtbot.wait(1)

    # Change interval size.
    v.interval = (.25, .75)
    ac(v.interval, (.25, .75))
    qtbot.wait(1)

    v.widen()
    ac(v.interval, (.1875, .8125))
    qtbot.wait(1)

    v.narrow()
    ac(v.interval, (.25, .75))
    qtbot.wait(1)

    v.go_to_start()
    qtbot.wait(1)
    assert v.interval[0] == 0

    v.go_to_end()
    qtbot.wait(1)
    assert v.interval[1] == duration

    # Widen the max interval.
    v.set_interval((0, duration))
    v.widen()
    qtbot.wait(1)

    v.toggle_show_labels(True)
    v.go_right()

    # Check auto scaling.
    db = v.data_bounds
    v.toggle_auto_scale(False)
    v.narrow()
    qtbot.wait(1)
    # Check that ymin and ymax have not changed.
    assert v.data_bounds[1] == db[1]
    assert v.data_bounds[3] == db[3]

    v.toggle_auto_update(True)
    assert v.do_show_labels
    qtbot.wait(1)

    v.toggle_highlighted_spikes(True)
    qtbot.wait(50)

    # Change channel scaling.
    bs = v.stacked.box_size
    v.decrease()
    qtbot.wait(1)

    v.increase()
    ac(v.stacked.box_size, bs, atol=.05)
    qtbot.wait(1)

    v.origin = 'bottom'
    v.switch_origin()
    assert v.origin == 'top'
    qtbot.wait(1)

    # Simulate spike selection.
    _clicked = []

    @connect(sender=v)
    def on_spike_click(sender, channel_id=None, spike_id=None, cluster_id=None, key=None):
        _clicked.append((channel_id, spike_id, cluster_id))

    mouse_click(qtbot, v.canvas, pos=(0., 0.), button='Left', modifiers=('Control',))

    v.set_state(v.state)

    assert len(_clicked[0]) == 3

    _stop_and_close(qtbot, v)
