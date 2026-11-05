"""Package existing release builds and a clean, runnable source archive."""
import hashlib
import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'deliverables'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUT.mkdir(exist_ok=True)
    apks = sorted((ROOT / 'build/app/outputs/flutter-apk').glob('app-*-release.apk'))
    assert len(apks) == 3, 'Build release APKs with --split-per-abi first.'
    bundle = ROOT / 'build/app/outputs/bundle/release/app-release.aab'
    assert bundle.is_file(), 'Build the release app bundle first.'
    catalog = json.loads((ROOT / 'assets/categories/catalog.json').read_text())
    assert len(catalog) == 27 and sum(c['count'] for c in catalog) == 315
    manifest = {}
    for source in [*apks, bundle]:
        target = OUT / source.name
        shutil.copy2(source, target)
        if target.suffix == '.apk':
            assert target.stat().st_size < 15_000_000, target.name
            with zipfile.ZipFile(target) as package:
                for category in catalog:
                    bundled = json.loads(package.read('assets/flutter_assets/' + category['asset']))
                    assert bundled == json.loads((ROOT / category['asset']).read_text())
        manifest[target.name] = dict(bytes=target.stat().st_size, sha256=digest(target))
    (OUT / 'build_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    files = [ROOT / path for path in [
        'README.md', 'VERIFICATION.md', 'pubspec.yaml', 'pubspec.lock',
        'analysis_options.yaml', '.fvmrc', '.gitignore', '.metadata',
        'deliverables/build_manifest.json',
    ]]
    for folder in ['lib', 'assets', 'android', 'test', 'integration_test',
                   'test_driver', 'scripts', 'tool', 'screenshots', 'designs', '.github', 'site']:
        for path in (ROOT / folder).rglob('*'):
            if not path.is_file():
                continue
            if set(path.relative_to(ROOT).parts) & {
                '.gradle', '.cxx', '.kotlin', '.idea', 'build', '__pycache__',
            }:
                continue
            if path.name in {'local.properties', 'key.properties',
                             'GeneratedPluginRegistrant.java', '.DS_Store'}:
                continue
            if path.suffix in {'.iml', '.jks', '.keystore', '.pyc'}:
                continue
            files.append(path)
    archive = OUT / 'muslim-azkar-source.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
        for path in sorted(files):
            package.write(path, 'muslim_azkar/' + str(path.relative_to(ROOT)))
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        for path in ['lib/main.dart', 'assets/categories/catalog.json',
                     'android/gradlew', 'android/gradle/wrapper/gradle-wrapper.jar']:
            assert 'muslim_azkar/' + path in package.namelist()
    checksums = [f'{digest(path)}  {path.name}'
                 for path in sorted([*(OUT / name for name in manifest), archive])]
    (OUT / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
    for name, details in manifest.items():
        print(f'{name}: {details["bytes"] / 1_000_000:.2f} MB')
    print(f'Source archive: {archive.stat().st_size:,} bytes; {len(files)} files; integrity verified.')


if __name__ == '__main__':
    main()
