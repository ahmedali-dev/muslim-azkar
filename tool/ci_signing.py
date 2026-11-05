"""Restore only repository-scoped signing secrets to ephemeral runner files."""
import base64
import os
from pathlib import Path

required = ['KEYSTORE_BASE64', 'STORE_PASSWORD', 'KEY_PASSWORD', 'KEY_ALIAS']
if any(not os.environ.get(name) for name in required):
    raise SystemExit('Configure the four ANDROID_* signing secrets before building release APKs.')
folder = Path(os.environ['RUNNER_TEMP']) / 'azkar-signing'
folder.mkdir(mode=0o700, exist_ok=True)
key = folder / 'release.jks'
key.write_bytes(base64.b64decode(os.environ['KEYSTORE_BASE64'], validate=True))
key.chmod(0o600)
# Java Properties must escape path separators and special password characters.
def escape(value):
    return ''.join('\\u%04x' % ord(c) if c in '\\:=#! \n\r\t' or ord(c) > 126 else c for c in value)
properties = {
    'storeFile': str(key.resolve()),
    'storePassword': os.environ['STORE_PASSWORD'],
    'keyPassword': os.environ['KEY_PASSWORD'],
    'keyAlias': os.environ['KEY_ALIAS'],
}
output = Path('android/key.properties')
output.write_text(''.join(f'{name}={escape(value)}\n' for name, value in properties.items()))
output.chmod(0o600)
print('Signing material restored to private temporary files.')
