class QuranAyah {
  const QuranAyah({
    required this.number,
    required this.surahNumber,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
    required this.hizbQuarter,
    required this.sajda,
  });

  final int number;
  final int surahNumber;
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;
  final int hizbQuarter;
  final bool sajda;

  factory QuranAyah.fromJson(Map<String, dynamic> json, int surahNumber) =>
      QuranAyah(
        number: _requiredInt(json, 'number'),
        surahNumber: surahNumber,
        numberInSurah: _requiredInt(json, 'numberInSurah'),
        text: _requiredString(json, 'text'),
        juz: _requiredInt(json, 'juz'),
        page: _requiredInt(json, 'page'),
        hizbQuarter: _requiredInt(json, 'hizbQuarter'),
        sajda: json['sajda'] == true,
      );
}

class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.ayahs,
  });

  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final List<QuranAyah> ayahs;

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    final number = _requiredInt(json, 'number');
    final ayahData = json['ayahs'];
    if (ayahData is! List) {
      throw const FormatException('سورة بلا آيات.');
    }
    return QuranSurah(
      number: number,
      name: _requiredString(json, 'name'),
      englishName: _requiredString(json, 'englishName'),
      englishNameTranslation: _requiredString(json, 'englishNameTranslation'),
      numberOfAyahs: _requiredInt(json, 'numberOfAyahs'),
      revelationType: _requiredString(json, 'revelationType'),
      ayahs: List.unmodifiable(
        ayahData.map(
          (ayah) => QuranAyah.fromJson(ayah as Map<String, dynamic>, number),
        ),
      ),
    );
  }
}

class QuranData {
  const QuranData({required this.surahs, required this.ayahs});

  static const surahCount = 114;
  static const ayahCount = 6236;
  static const pageCount = 604;

  final List<QuranSurah> surahs;
  final List<QuranAyah> ayahs;

  QuranSurah surah(int number) => surahs[number - 1];
  QuranAyah ayah(int globalNumber) => ayahs[globalNumber - 1];

  List<QuranAyah> page(int pageNumber) =>
      ayahs.where((ayah) => ayah.page == pageNumber).toList(growable: false);

  factory QuranData.fromApiResponse(Map<String, dynamic> response) {
    if (response['code'] != 200 || response['status'] != 'OK') {
      throw const FormatException('تعذّر التحقق من استجابة مصدر القرآن.');
    }
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('صيغة بيانات القرآن غير مكتملة.');
    }
    final rawSurahs = data['surahs'];
    if (rawSurahs is! List || rawSurahs.length != surahCount) {
      throw const FormatException('لم تكتمل قائمة سور القرآن.');
    }
    final surahs = List<QuranSurah>.unmodifiable(
      rawSurahs.map((surah) => QuranSurah.fromJson(surah as Map<String, dynamic>)),
    );
    for (var i = 0; i < surahs.length; i++) {
      final surah = surahs[i];
      if (surah.number != i + 1 ||
          surah.numberOfAyahs != surah.ayahs.length ||
          surah.ayahs.isEmpty) {
        throw const FormatException('بيانات إحدى السور غير مكتملة.');
      }
    }
    final ayahs = List<QuranAyah>.unmodifiable(
      surahs.expand((surah) => surah.ayahs),
    );
    if (ayahs.length != ayahCount) {
      throw const FormatException('لم يكتمل نص القرآن.');
    }
    final pagesFound = <int>{};
    for (var i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      if (ayah.number != i + 1 ||
          ayah.numberInSurah !=
              (i == 0 || ayahs[i - 1].surahNumber != ayah.surahNumber
                  ? 1
                  : ayahs[i - 1].numberInSurah + 1) ||
          ayah.page < 1 ||
          ayah.page > pageCount ||
          ayah.juz < 1 ||
          ayah.juz > 30) {
        throw const FormatException('تسلسل آيات القرآن غير مكتمل.');
      }
      pagesFound.add(ayah.page);
    }
    if (pagesFound.length != pageCount ||
        List.generate(pageCount, (index) => index + 1)
            .any((page) => !pagesFound.contains(page))) {
      throw const FormatException('ترقيم صفحات القرآن غير مكتمل.');
    }
    return QuranData(surahs: surahs, ayahs: ayahs);
  }
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('حقل غير صالح: $key');
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('حقل غير صالح: $key');
  }
  return value;
}
