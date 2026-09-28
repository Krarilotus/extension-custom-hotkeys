from pathlib import Path
import xml.etree.ElementTree as ET

import yaml

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {'en', 'de', 'fr', 'es', 'hu', 'tr', 'ru', 'ch', 'fa'}


def test_optional_legacy_has_required_conflict_value_without_dependency_or_switch():
    definition = yaml.safe_load((ROOT / 'definition.yml').read_text(encoding='utf-8'))
    assert definition['display-name'] == 'Custom Hotkeys'
    assert definition['version'] == '0.2.2'
    assert definition['tags'] == ['hotkeys', 'interface', 'tools']
    assert 'family' not in definition
    assert 'ucp2-legacy' not in definition['dependencies']
    config = yaml.safe_load((ROOT / 'config.yml').read_text(encoding='utf-8'))['config-sparse']
    assert config['plugins'] == {}
    assert config.get('load-order', []) == []
    assert config['modules'] == {'ucp2-legacy': {'config': {
        'o_keys': {'enabled': {'contents': {'required-value': False}}}}}}
    assert not (ROOT / 'options.yml').exists()
    files = {entry.attrib['src'] for entry in ET.parse(ROOT / 'files.xml').findall('./files/file')}
    assert files == {'definition.yml', 'config.yml', 'init.lua', 'code', 'README.md', 'locale'}


def test_all_store_languages_present_the_ingame_editor_without_release_notes():
    paths = list((ROOT / 'locale').glob('description-*.md'))
    assert {p.stem.removeprefix('description-') for p in paths} == LANGUAGES
    for path in paths:
        text = path.read_text(encoding='utf-8')
        assert text.startswith('# Custom Hotkeys\n')
        assert 'F12' in text
        assert ' > ' in text and any(key in text for key in ('Enter', 'Eingabe', 'Entrée', 'Intro'))
        assert 'v0.2.1/docs/images/hotkeys-010-editor-ingame.jpg' in text
        assert '\ufffd' not in text
        assert not any(term in text for term in (
            'TL;DR', 'UCP2-Legacy', 'o_keys.enabled', 'Recorder',
            'Automarket', 'SHC 1.41', 'Extreme 1.41'))


def test_discovery_tags_have_translated_labels_in_every_store_language():
    assert {p.stem for p in (ROOT / 'locale').glob('*.yml')} == LANGUAGES
    for lang in LANGUAGES:
        labels = yaml.safe_load((ROOT / 'locale' / f'{lang}.yml').read_text(encoding='utf-8'))
        assert set(labels) == {'tags.hotkeys', 'tags.interface', 'tags.tools'}
        assert all(isinstance(value, str) and value.strip() and '?' not in value
                   for value in labels.values())


def test_all_runtime_lua_parses(lua):
    # Includes native-only adapters that cannot execute in the host architecture.
    load = lua.eval('function(path) return assert(loadfile(path)) ~= nil end')
    for path in (ROOT / 'code').rglob('*.lua'):
        assert load(path.as_posix())
