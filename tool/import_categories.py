"""Import the browser capture into offline assets without rewriting Arabic text."""
import argparse
import json
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
NAMES = {
    1: 'morning', 2: 'evening', 9: 'afterPrayer', 3: 'tasbih',
    11: 'sleep', 12: 'waking', 22: 'prayer', 20: 'comprehensiveDua',
    21: 'propheticDua', 15: 'quranicDua', 28: 'prophetsDua',
    14: 'miscellaneous', 5: 'adhan', 6: 'mosque', 10: 'ablution',
    4: 'home', 7: 'toilet', 13: 'food', 17: 'hajjUmrah',
    16: 'quranCompletion', 18: 'duaMerit', 19: 'dhikrMerit',
    24: 'surahMerit', 23: 'quranMerit', 25: 'namesOfAllah',
    27: 'deceased', 26: 'ruqyah',
}

def fingerprint(item):
    value = json.dumps([item['text'], item['repeat'], item['source'], item['virtue']],
                       ensure_ascii=False, separators=(',', ':')).encode('utf-16-le')
    result = 2166136261
    for offset in range(0, len(value), 2):
        result = ((result ^ int.from_bytes(value[offset:offset+2], 'little')) * 16777619) & 0xffffffff
    return result

def encode(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + '\n'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    capture = json.loads((ROOT / 'tool/source/categories_capture.json').read_text())
    categories = capture['categories']
    assert capture['selector'] == '.card-body.text-primary-emphasis'
    assert len(categories) == len(NAMES) == 27
    assert {c['categoryId'] for c in categories} == set(NAMES)
    assert all(c['title'] != 'القرآن' and '/azkar/' in c['url'] for c in categories)
    outputs = {}
    catalog = []
    enum_entries = []
    for category in categories:
        source_id = category['categoryId']
        name = NAMES[source_id]
        items = category['items']
        assert items and len(items) == len(category['fingerprints'])
        for index, (item, expected) in enumerate(zip(items, category['fingerprints']), 1):
            assert item['id'] == index and item['text']
            assert isinstance(item['repeat'], int) and item['repeat'] >= 0
            assert fingerprint(item) == expected, (category['title'], index)
        path = f'assets/{name}_azkar.json' if source_id in (1, 2) else f'assets/categories/{source_id}.json'
        if source_id in (1, 2):
            # Preserve existing item IDs and saved progress for installed users.
            assert json.loads((ROOT / path).read_text()) == items
        outputs[path] = encode(items)
        catalog.append(dict(id=source_id, key=name, title=category['title'],
                            url=unquote(category['url']), asset=path, count=len(items)))
        literal = lambda value: json.dumps(value, ensure_ascii=False)
        enum_entries.append(f'  {name}({source_id}, {literal(category["title"])}, {literal(unquote(category["url"]))})')
    outputs['assets/categories/catalog.json'] = encode(catalog)
    model_path = ROOT / 'lib/models/zikr.dart'
    zikr_class = model_path.read_text().split('class Zikr {', 1)[1]
    header = '''// Category order and titles follow the captured IslamBook menu.
enum AzkarPeriod {
''' + ',\n'.join(enum_entries) + ''';

  const AzkarPeriod(this.sourceId, this.title, this.sourceUrl);
  final int sourceId;
  final String title;
  final String sourceUrl;

  static const reminderPeriods = [morning, evening];
  bool get supportsReminder => this == morning || this == evening;
  String get assetPath => switch (this) {
    morning => 'assets/morning_azkar.json',
    evening => 'assets/evening_azkar.json',
    _ => 'assets/categories/$sourceId.json',
  };
}

class Zikr {''' + zikr_class
    if not args.check:
        model_path.write_text(header)
    for path, value in outputs.items():
        target = ROOT / path
        if args.check:
            assert json.loads(target.read_text()) == json.loads(value), path
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(value)
    count = sum(len(c['items']) for c in categories)
    assert count == 315
    print(f'Verified {len(categories)} categories / {count} items against browser fingerprints; القرآن excluded.')

if __name__ == '__main__':
    main()
