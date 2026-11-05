#!/bin/sh
set -eu
"${FLUTTER_BIN:-flutter}" pub get
"${FLUTTER_BIN:-flutter}" analyze
"${FLUTTER_BIN:-flutter}" test
"${FLUTTER_BIN:-flutter}" build apk --release --split-per-abi
python3 - <<'PY'
from pathlib import Path
apks = list(Path('build/app/outputs/flutter-apk').glob('app-*-release.apk'))
assert len(apks) == 3, f'Expected three architecture APKs, found {len(apks)}'
for apk in sorted(apks):
    size = apk.stat().st_size
    print(f'{apk.name}: {size / 1_000_000:.2f} MB')
    assert size < 15_000_000, f'{apk.name} exceeds the 15 MB budget'
PY
