import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def test_reference_game_addresses_and_hash_allowlists_never_reenter_runtime():
    addresses = set(json.loads((ROOT / 'tests/fixtures/reference_addresses.json').read_text()).values())
    addresses = {value for value in addresses if value >= 0x400000}
    for path in (ROOT / 'code').rglob('*.lua'):
        text = re.sub(r'--[^\n]*', '', path.read_text(encoding='utf-8'))
        literals = {int(value, 16) for value in re.findall(r'0x[0-9a-fA-F]+', text)}
        assert not literals & addresses, path
        assert 'executable.unsupported' not in text, path
    assert not (ROOT / 'code/executable.lua').exists()
    assert not (ROOT / 'code/native/identity.lua').exists()
