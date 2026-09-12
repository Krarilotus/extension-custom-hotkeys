import hashlib
import json
import zipfile

from tools import build


def test_committed_module_package_is_reproducible_and_excludes_test_data(tmp_path):
    first, receipt = build.build(tmp_path / 'first')
    second, other = build.build(tmp_path / 'second')
    assert first.read_bytes() == second.read_bytes()
    assert receipt['sha256'] == other['sha256'] == hashlib.sha256(first.read_bytes()).hexdigest()
    with zipfile.ZipFile(first) as archive:
        names = set(archive.namelist())
        assert {'init.lua', 'definition.yml', 'config.yml', 'build.json', 'code/native/runtime.lua'} <= names
        assert all(name in ('init.lua', 'definition.yml', 'config.yml', 'README.md', 'build.json')
                   or name.startswith('code/') for name in names)
        assert not any(name.endswith(('.exe', '.dll')) or 'probe' in name for name in names)
        embedded = json.loads(archive.read('build.json'))
        assert embedded['commit'] == receipt['commit']
        for name, digest in embedded['files'].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest


def test_builder_rejects_a_tree_without_module_entry_points(monkeypatch):
    import pytest
    def incomplete(*args):
        if args[0] == 'rev-parse':
            return b'a' * 40
        if args[0] == 'ls-tree':
            return b'code/launch.lua\0'
        return b'return {}'
    monkeypatch.setattr(build, 'git', incomplete)
    with pytest.raises(ValueError, match='entry points'):
        build.payload('HEAD')
