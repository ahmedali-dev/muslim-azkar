"""Check that the static Arabic landing page has working local references."""
from html.parser import HTMLParser
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1] / 'site'
class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.local = []
        self.ids = set()
        self.anchors = []
        self.rtl = False
    def handle_starttag(self, tag, attributes):
        attributes = dict(attributes)
        if tag == 'html':
            self.rtl = attributes.get('lang') == 'ar' and attributes.get('dir') == 'rtl'
        if 'id' in attributes:
            self.ids.add(attributes['id'])
        for key in ['href', 'src']:
            value = attributes.get(key, '')
            if value.startswith('#') and len(value) > 1:
                self.anchors.append(value[1:])
            elif value and not value.startswith(('https:', 'http:', '#', 'data:')):
                self.local.append(value)
page = Page()
html = (ROOT / 'index.html').read_text()
page.feed(html)
assert page.rtl
for local in page.local + re.findall(r"url\('([^']+)'\)", html):
    assert (ROOT / local).is_file(), local
assert set(page.anchors) <= page.ids
assert '<script' not in html, 'Core landing content must work without JavaScript.'
assert 'releases/latest/download/app-arm64-v8a-release.apk' in html
print('Arabic RTL landing page checked: assets, anchors, fonts, and download links present.')
