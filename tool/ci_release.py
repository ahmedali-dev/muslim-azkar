"""Check tag/version consistency and stage validated GitHub Release assets."""
import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'^version:\s*([^+\s]+)', (ROOT / 'pubspec.yaml').read_text(), re.M).group(1)
parser = argparse.ArgumentParser()
parser.add_argument('--check-tag')
args = parser.parse_args()
if args.check_tag:
    if args.check_tag != 'v' + version:
        raise SystemExit(f'Tag must match pubspec version: v{version}')
    print(f'Validated release tag v{version}.')
else:
    output = ROOT / 'release-files'
    output.mkdir(exist_ok=True)
    catalog = json.loads((ROOT / 'assets/categories/catalog.json').read_text())
    apks = sorted((ROOT / 'build/app/outputs/flutter-apk').glob('app-*-release.apk'))
    assert len(apks) == 3, 'Expected three architecture APKs'
    bundle = ROOT / 'build/app/outputs/bundle/release/app-release.aab'
    assert bundle.is_file()
    manifest = {'version': version, 'files': {}}
    for source in [*apks, bundle]:
        if source.suffix == '.apk':
            assert source.stat().st_size < 15_000_000, f'{source.name} exceeds 15 MB'
            with zipfile.ZipFile(source) as package:
                for category in catalog:
                    assert json.loads(package.read('assets/flutter_assets/' + category['asset'])) == json.loads((ROOT / category['asset']).read_text())
        target = output / source.name
        shutil.copy2(source, target)
        manifest['files'][target.name] = {'bytes': target.stat().st_size, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
        print(f'{target.name}: {target.stat().st_size / 1_000_000:.2f} MB')
    metadata = output / 'build-manifest.json'
    metadata.write_text(json.dumps(manifest, indent=2) + '\n')
    checksums = [f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}' for path in sorted(output.iterdir()) if path.is_file() and path.name != 'SHA256SUMS.txt']
    (output / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
