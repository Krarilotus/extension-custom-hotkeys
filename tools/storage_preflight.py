"""Check free space before staging or reserving a native desktop test slot."""
import argparse
import json
import shutil
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('installation', type=Path)
    args = parser.parse_args()
    root = args.installation.resolve(strict=True)
    if not root.is_dir():
        parser.error('installation must be an existing directory')
    free = shutil.disk_usage(root).free
    minimum = 2 * 1024 ** 3
    ready = free >= minimum
    print(json.dumps({'installation': str(root), 'free_bytes': free,
                      'required_free_bytes': minimum,
                      'status': 'ready' if ready else 'blocked',
                      'scope': 'storage only; queue and input checks still required'}))
    return 0 if ready else 1


if __name__ == '__main__':
    raise SystemExit(main())
