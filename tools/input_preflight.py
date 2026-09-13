"""Read-only transport capability check. Never certifies gameplay acceptance."""
import argparse
import hashlib
import json
import re
from pathlib import Path


def records(text):
    decoder = json.JSONDecoder()
    for match in re.finditer(r'CUSTOM-HOTKEYS-(PROBE|RAW|LIFECYCLE)\s+', text):
        try:
            value, _ = decoder.raw_decode(text[match.end():])
        except ValueError as exc:
            raise ValueError(f'malformed {match[1]} record') from exc
        if not isinstance(value, dict):
            raise ValueError(f'invalid {match[1]} record')
        yield match[1], value


def analyze(text):
    failures, missing = [], []
    installed = 0
    downs, zero, repeats = 0, 0, 0
    held, pairs = set(), set()
    lost, returned = False, False
    for kind, value in records(text):
        if kind == 'PROBE':
            installed += 1
            if (value.get('installed') is not True
                    or type(value.get('priority')) is not int
                    or type(value.get('rawPriority')) is not int
                    or not value['rawPriority'] < value['priority'] < -100000):
                failures.append('listener-order-unverified')
        elif kind == 'LIFECYCLE':
            # Destruction/close alone is not a focus round trip.
            if value.get('message') in (6, 7, 8, 28):
                if value.get('focused') is False:
                    lost = True
                    held.clear()
                elif value.get('focused') is True and lost:
                    returned = True
            if value.get('message') == 130:
                held.clear()
        else:
            if any(type(value.get(k)) is not int for k in ('msg', 'wp', 'lp')):
                raise ValueError('invalid raw message fields')
            msg, lp = value['msg'], value['lp'] & 0xffffffff
            if msg not in (256, 257, 260, 261):
                raise ValueError('unexpected raw message')
            scan, extended = (lp >> 16) & 255, bool(lp & (1 << 24))
            up, previous = msg in (257, 261), bool(lp & (1 << 30))
            if bool(lp & (1 << 31)) != up or (up and not previous):
                failures.append('invalid-key-transition-bits')
            if value.get('scan') != scan:
                failures.append('raw-scan-disagrees-with-lparam')
            if scan == 0:
                zero += 1
                continue
            if scan > 127 or (lp & 65535) == 0:
                failures.append('unsupported-scan-or-repeat-count')
                continue
            key = (scan, extended)
            if up:
                if key in held:
                    pairs.add(key)
                    held.remove(key)
            else:
                downs += 1
                if previous and key in held:
                    repeats += 1
                held.add(key)
    if installed != 1:
        failures.append('expected-one-probe-session')
    if zero:
        failures.append('zero-scan-input')
    if not any(scan not in (28, 29, 42, 54, 56) for scan, _ in pairs):
        missing.append('ordinary-key-down-up')
    if not {(28, False), (28, True)} <= pairs:
        missing.append('main-and-numpad-enter-distinction')
    if not repeats:
        missing.append('held-key-repeat')
    if not returned:
        missing.append('focus-loss-and-return')
    return {'scope': 'minimum input transport evidence only',
            'gameplay_acceptance': 'not evaluated',
            'status': 'blocked' if failures or missing else 'minimum-evidence-present',
            'failures': sorted(set(failures)), 'missing_evidence': missing,
            'observations': {'physical_downs': downs, 'zero_scan_messages': zero,
                             'paired_keys': len(pairs), 'repeats': repeats,
                             'focus_round_trip': returned}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    parser.add_argument('--transport', required=True,
                        help='Exact input method/version; record manual input explicitly')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    data = args.log.read_bytes()
    try:
        result = analyze(data.decode('utf-8-sig'))
    except (ValueError, UnicodeError) as exc:
        result = {'status': 'blocked', 'failures': [str(exc)],
                  'gameplay_acceptance': 'not evaluated'}
    result.update(log_sha256=hashlib.sha256(data).hexdigest(), transport=args.transport)
    rendered = json.dumps(result, indent=2) + '\n'
    if args.output:
        args.output.write_text(rendered, encoding='utf-8')
    print(rendered, end='')
    return 0 if result['status'] == 'minimum-evidence-present' else 2


if __name__ == '__main__':
    raise SystemExit(main())
