"""Build a reproducible development module from an exact committed source tree.

No game binaries, dependencies, profiles, test fixtures or diagnostics are bundled.
This creates a local artifact only; it does not install, launch or publish it.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])


def payload(revision):
    commit = git('rev-parse', '--verify', revision + '^{commit}').decode().strip()
    names = git('ls-tree', '-r', '--name-only', '-z', commit).decode().split('\0')
    selected = sorted(name for name in names if name in ('init.lua', 'definition.yml', 'README.md')
                      or name.startswith('code/') and name.endswith('.lua')
                      or name.startswith('docs/') and name.endswith('.md'))
    files = {name: git('show', commit + ':' + name) for name in selected}
    if not {'init.lua', 'definition.yml', 'code/launch.lua', 'code/preflight.lua'} <= files.keys():
        raise ValueError('Committed tree does not contain the module entry points')
    definition = files['definition.yml'].decode('utf-8')
    def field(key, pattern):
        matches = re.findall(r'^' + key + ': (' + pattern + r')$', definition, re.M)
        if len(matches) != 1:
            raise ValueError('Invalid module ' + key)
        return matches[0]
    name = field('name', r'[a-z][a-z0-9-]+')
    version = field('version', r'\d+\.\d+\.\d+')
    if field('type', 'module') != 'module':
        raise ValueError('Native implementation must be a module')
    receipt = {'name': name, 'version': version, 'commit': commit,
               'status': 'development; required native acceptance incomplete',
               'files': {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}}
    files['build.json'] = (json.dumps(receipt, indent=2, sort_keys=True) + '\n').encode()
    return name, version, receipt, files


def build(destination, revision='HEAD'):
    name, version, receipt, files = payload(revision)
    destination.mkdir(parents=True, exist_ok=True)
    artifact = destination / f'{name}-{version}.zip'
    with zipfile.ZipFile(artifact, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data, compresslevel=9)
    with zipfile.ZipFile(artifact) as archive:
        if archive.testzip() is not None or set(archive.namelist()) != set(files):
            raise ValueError('Archive verification failed')
        for name, data in files.items():
            if archive.read(name) != data:
                raise ValueError('Archive payload mismatch: ' + name)
    receipt.update(archive=artifact.name, bytes=artifact.stat().st_size,
                   sha256=hashlib.sha256(artifact.read_bytes()).hexdigest())
    artifact.with_suffix('.build.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    return artifact, receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    parser.add_argument('--revision', default='HEAD')
    args = parser.parse_args()
    artifact, receipt = build(args.output, args.revision)
    print(json.dumps({'artifact': str(artifact), **receipt}, indent=2))


if __name__ == '__main__':
    main()
