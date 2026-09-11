import importlib.util
import json
from pathlib import Path

import pytest

spec = importlib.util.spec_from_file_location(
    'input_preflight', Path(__file__).resolve().parents[1] / 'tools/input_preflight.py')
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)


def record(kind, **fields):
    return 'log prefix: CUSTOM-HOTKEYS-' + kind + ' ' + json.dumps(fields) + '\n'


def installed():
    return record('PROBE', installed=True, priority=-110000, rawPriority=-110001)


def key(scan, up=False, extended=False, repeat=False):
    lp = 1 | (scan << 16) | (int(extended) << 24)
    lp |= int(up or repeat) << 30 | int(up) << 31
    return record('RAW', msg=257 if up else 256, wp=13, lp=lp, scan=scan)


def complete():
    result = installed()
    for scan, extended in ((17, False), (28, False), (28, True)):
        result += key(scan, extended=extended)
        result += key(scan, extended=extended, repeat=True)
        result += key(scan, extended=extended, up=True)
    result += record('LIFECYCLE', message=8, focused=False)
    result += record('LIFECYCLE', message=7, focused=True)
    return result


def test_zero_scan_native_receipt_blocks_even_with_other_valid_input():
    result = preflight.analyze(complete() + key(0) + key(0, up=True))
    assert result['status'] == 'blocked'
    assert result['observations']['zero_scan_messages'] == 2
    assert 'zero-scan-input' in result['failures']


def test_empty_or_concatenated_sessions_cannot_pass():
    for text in ('', complete() + complete()):
        assert 'expected-one-probe-session' in preflight.analyze(text)['failures']


def test_minimum_transport_evidence_never_claims_gameplay_acceptance():
    result = preflight.analyze(complete())
    assert result['status'] == 'minimum-evidence-present'
    assert result['gameplay_acceptance'] == 'not evaluated'


def test_shutdown_is_not_focus_round_trip_and_keyup_is_not_repeat():
    result = preflight.analyze(installed() + key(17) + key(17, up=True)
        + record('LIFECYCLE', message=8, focused=False)
        + record('LIFECYCLE', message=130, focused=False))
    assert 'held-key-repeat' in result['missing_evidence']
    assert 'focus-loss-and-return' in result['missing_evidence']


def test_scan_field_cannot_substitute_for_actual_lparam():
    result = preflight.analyze(installed() + record('RAW', msg=256, wp=87, lp=1, scan=17))
    assert 'raw-scan-disagrees-with-lparam' in result['failures']
    assert 'zero-scan-input' in result['failures']


def test_down_and_up_across_focus_loss_do_not_make_a_clean_pair():
    result = preflight.analyze(installed() + key(17)
        + record('LIFECYCLE', message=8, focused=False)
        + record('LIFECYCLE', message=7, focused=True) + key(17, up=True))
    assert result['observations']['paired_keys'] == 0
    assert 'ordinary-key-down-up' in result['missing_evidence']


@pytest.mark.parametrize('bad', ['{', '[]', '{"msg":256,"wp":87,"lp":"1"}'])
def test_malformed_evidence_is_rejected(bad):
    with pytest.raises(ValueError):
        preflight.analyze(installed() + 'CUSTOM-HOTKEYS-RAW ' + bad)


def test_observer_after_graphics_wrapper_is_not_accepted():
    result = preflight.analyze(complete().replace('"priority": -110000', '"priority": 0'))
    assert 'listener-order-unverified' in result['failures']
