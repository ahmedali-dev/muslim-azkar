import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_azkar/data/azkar_repository.dart';
import 'package:muslim_azkar/models/zikr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all linked categories load offline, except the standalone Quran link',
    () async {
      final data = await AzkarRepository.load();
      expect(data.length, 27);
      expect(data.values.fold<int>(0, (sum, items) => sum + items.length), 315);
      expect(data.keys.any((c) => c.title == 'القرآن'), false);
      expect(
        data.keys.every(
          (c) => Uri.parse(c.sourceUrl).path.startsWith('/azkar/'),
        ),
        true,
      );
      expect(data[AzkarPeriod.quranicDua], isNotEmpty);
      expect(data[AzkarPeriod.quranCompletion], isNotEmpty);
      expect(data[AzkarPeriod.morning]!.length, 31);
      expect(data[AzkarPeriod.evening]!.length, 30);
      for (final items in data.values) {
        expect(items.map((z) => z.id).toSet().length, items.length);
        expect(items.every((z) => z.text.isNotEmpty && z.repeat >= 0), true);
      }
      expect(
        data[AzkarPeriod.morning]!.fold(0, (sum, z) => sum + z.repeat),
        464,
      );
      expect(
        data[AzkarPeriod.evening]!.fold(0, (sum, z) => sum + z.repeat),
        364,
      );
    },
  );
}
