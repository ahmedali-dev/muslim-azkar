// Category order and titles follow the captured IslamBook menu.
enum AzkarPeriod {
  morning(1, "أذكار الصباح", "https://www.islambook.com/azkar/1/أذكار-الصباح"),
  evening(2, "أذكار المساء", "https://www.islambook.com/azkar/2/أذكار-المساء"),
  afterPrayer(
    9,
    "أذكار بعد الصلاة",
    "https://www.islambook.com/azkar/9/أذكار-بعد-السلام-من-الصلاة-المفروضة",
  ),
  tasbih(
    3,
    "تسابيح",
    "https://www.islambook.com/azkar/3/تسابيح-تسبيح-السبحة-أذكار-عظيمة",
  ),
  sleep(
    11,
    "أذكار النوم",
    "https://www.islambook.com/azkar/11/أذكار-النوم-والأحلام",
  ),
  waking(
    12,
    "أذكار الاستيقاظ",
    "https://www.islambook.com/azkar/12/أذكار-الإستيقاظ-من-النوم",
  ),
  prayer(22, "أذكار الصلاة", "https://www.islambook.com/azkar/22/أذكار-الصلاة"),
  comprehensiveDua(
    20,
    "جوامع الدعاء",
    "https://www.islambook.com/azkar/20/جوامع-الدعاء",
  ),
  propheticDua(
    21,
    "أدعية نبوية",
    "https://www.islambook.com/azkar/21/أدعية-النبي-صلى-الله-عليه-وسلم",
  ),
  quranicDua(
    15,
    "الأدعية القرآنية",
    "https://www.islambook.com/azkar/15/الأدعية-القرآنية",
  ),
  prophetsDua(
    28,
    "أدعية الأنبياء",
    "https://www.islambook.com/azkar/28/أدعية-الأنبياء-من-القرآن-الكريم",
  ),
  miscellaneous(
    14,
    "أذكار متفرقة",
    "https://www.islambook.com/azkar/14/أذكار-متفرقة",
  ),
  adhan(
    5,
    "أذكار الآذان",
    "https://www.islambook.com/azkar/5/أذكار-عند-سماع-الآذان",
  ),
  mosque(6, "أذكار المسجد", "https://www.islambook.com/azkar/6/أذكار-المسجد"),
  ablution(
    10,
    "أذكار الوضوء",
    "https://www.islambook.com/azkar/10/أذكار-الوضوء",
  ),
  home(
    4,
    "أذكار المنزل",
    "https://www.islambook.com/azkar/4/أذكار-دخول-وخروج-المنزل",
  ),
  toilet(
    7,
    "أذكار الخلاء",
    "https://www.islambook.com/azkar/7/أذكار-دخول-وخروج-الخلاء",
  ),
  food(
    13,
    "أذكار الطعام",
    "https://www.islambook.com/azkar/13/أذكار-الطعام-والشراب-والضيف",
  ),
  hajjUmrah(
    17,
    "أذكار الحج والعمرة",
    "https://www.islambook.com/azkar/17/أذكار-الحج-والعمرة",
  ),
  quranCompletion(
    16,
    "دعاء ختم القرآن الكريم",
    "https://www.islambook.com/azkar/16/دعاء-ختم-القرآن-الكريم",
  ),
  duaMerit(18, "فضل الدعاء", "https://www.islambook.com/azkar/18/فضل-الدعاء"),
  dhikrMerit(19, "فضل الذكر", "https://www.islambook.com/azkar/19/فضل-الذكر"),
  surahMerit(24, "فضل السور", "https://www.islambook.com/azkar/24/فضائل-السور"),
  quranMerit(
    23,
    "فضل القرآن",
    "https://www.islambook.com/azkar/23/فضائل-القرآن",
  ),
  namesOfAllah(
    25,
    "أسماء الله الحسنى",
    "https://www.islambook.com/azkar/25/أسماء-الله-الحسنى",
  ),
  deceased(
    27,
    "أدعية للميّت",
    "https://www.islambook.com/azkar/27/أدعية-للميت",
  ),
  ruqyah(
    26,
    "الرُّقية الشرعية",
    "https://www.islambook.com/azkar/26/الرقية-الشرعية-من-القرآن-والسنة",
  );

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

class Zikr {
  const Zikr({
    required this.id,
    required this.text,
    required this.repeat,
    this.source = '',
    this.virtue = '',
  });

  factory Zikr.fromJson(Map<String, dynamic> json) => Zikr(
    id: json['id'] as int,
    text: json['text'] as String,
    repeat: json['repeat'] as int,
    source: json['source'] as String? ?? '',
    virtue: json['virtue'] as String? ?? '',
  );

  final int id;
  final String text;
  final int repeat;

  // A source count of zero denotes reading without a prescribed repetition.
  bool get hasRepetitions => repeat > 0;
  int get progressTarget => hasRepetitions ? repeat : 1;
  final String source;
  final String virtue;
}
