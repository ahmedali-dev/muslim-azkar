import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_azkar/data/quran_repository.dart';
import 'package:muslim_azkar/models/quran.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the complete Quran is bundled and loads without network access',
    () async {
      final data = await QuranRepository().loadBundled();

      expect(data.surahs, hasLength(QuranData.surahCount));
      expect(data.ayahs, hasLength(QuranData.ayahCount));
      expect(data.page(1), isNotEmpty);
      expect(data.page(QuranData.pageCount), isNotEmpty);
      expect(data.surahs.first.name, 'سُورَةُ ٱلْفَاتِحَةِ');
      expect(data.surahs.last.name, 'سُورَةُ النَّاسِ');
      expect(
        data.ayahs.first.text,
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ\n',
      );
    },
  );
}
