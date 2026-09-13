from pathlib import Path
import xml.etree.ElementTree as ET

import yaml

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {'en', 'de', 'fr', 'es', 'hu', 'tr', 'ru', 'ch', 'fa'}


def test_optional_legacy_has_required_conflict_value_without_dependency_or_switch():
    definition = yaml.safe_load((ROOT / 'definition.yml').read_text(encoding='utf-8'))
    assert 'ucp2-legacy' not in definition['dependencies']
    config = yaml.safe_load((ROOT / 'config.yml').read_text(encoding='utf-8'))['config-sparse']
    assert config['plugins'] == {}
    assert config.get('load-order', []) == []
    assert config['modules'] == {'ucp2-legacy': {'config': {
        'o_keys': {'enabled': {'contents': {'required-value': False}}}}}}
    assert not (ROOT / 'options.yml').exists()
    files = {entry.attrib['src'] for entry in ET.parse(ROOT / 'files.xml').findall('./files/file')}
    assert files == {'definition.yml', 'config.yml', 'init.lua', 'code', 'README.md'}


def test_all_store_languages_describe_access_recovery_and_optional_legacy():
    paths = list((ROOT / 'locale').glob('description-*.md'))
    assert {p.stem.removeprefix('description-') for p in paths} == LANGUAGES
    for path in paths:
        text = path.read_text(encoding='utf-8')
        assert 'F12' in text
        assert any(chord in text for chord in ('Shift+F12', 'Umschalt+F12', 'Maj+F12', 'Mayús+F12'))
        assert 'o_keys.enabled' in text and 'UCP2-Legacy' in text
        assert 'Recorder' in text and '1.41' in text


def test_all_runtime_lua_parses(lua):
    # Includes native-only adapters that cannot execute in the host architecture.
    load = lua.eval('function(path) return assert(loadfile(path)) ~= nil end')
    for path in (ROOT / 'code').rglob('*.lua'):
        assert load(path.as_posix())
