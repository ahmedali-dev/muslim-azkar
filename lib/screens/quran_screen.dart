import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quran_repository.dart';
import '../models/quran.dart';
import '../providers/app_state.dart';
import '../providers/quran_controller.dart';
import '../widgets/glass_surface.dart';
import 'settings_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late final QuranController _quran;
  late final PageController _ayahPager;
  late int _currentAyahNumber;

  @override
  void initState() {
    super.initState();
    _currentAyahNumber = context.read<AppState>().quranLastAyahNumber;
    _ayahPager = PageController(initialPage: _currentAyahNumber - 1);
    _quran = QuranController(QuranRepository());
    unawaited(_quran.load());
  }

  @override
  void dispose() {
    _quran.dispose();
    _ayahPager.dispose();
    super.dispose();
  }

  void _setAyah(int number) {
    final data = _quran.data;
    if (data == null) return;
    final value = number.clamp(1, data.ayahs.length);
    setState(() => _currentAyahNumber = value);
    context.read<AppState>().saveQuranPosition(value);
    if (_ayahPager.hasClients && _ayahPager.page?.round() != value - 1) {
      _ayahPager.animateToPage(
        value - 1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _movePage(QuranData data, int delta) {
    final currentPage = data.ayah(_currentAyahNumber).page;
    final nextPage = (currentPage + delta).clamp(1, QuranData.pageCount);
    _setAyah(data.page(nextPage).first.number);
  }

  Future<void> _chooseSurah(QuranData data) async {
    final number = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranSurahPicker(surahs: data.surahs),
    );
    if (number != null && mounted) {
      _setAyah(data.surah(number).ayahs.first.number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return AnimatedBuilder(
      animation: _quran,
      builder: (context, _) {
        final data = _quran.data;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        if (data != null) {
          _currentAyahNumber = _currentAyahNumber.clamp(1, data.ayahs.length);
        }
        final ayah = data == null ? null : data.ayah(_currentAyahNumber);
        final design = app.settings.quranReaderDesign;
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: const GlassSurface(
              radius: 0,
              child: SizedBox.expand(),
            ),
            title: const Text('القرآن الكريم'),
            actions: [
              if (data != null)
                IconButton(
                  tooltip: 'اختيار السورة',
                  onPressed: () => _chooseSurah(data),
                  icon: const Icon(Icons.menu_book_rounded),
                ),
              IconButton(
                tooltip: 'الإعدادات',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                tooltip: 'تحديث نص القرآن من المصدر',
                onPressed: _quran.busy ? null : _quran.refresh,
                icon: _quran.refreshing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: data == null
                ? _loadingOrError(_quran, colors)
                : _reader(
                    context,
                    data,
                    ayah!,
                    design,
                    app.settings.fontSize,
                    _quran.error,
                  ),
          ),
        );
      },
    );
  }

  Widget _loadingOrError(QuranController controller, ColorScheme colors) {
    if (controller.busy) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.primary),
                const SizedBox(height: 20),
                const Text(
                  'جارٍ تحميل نص القرآن كاملًا لأول مرة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيُحفظ على جهازك لتتمكن من القراءة دون اتصال.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 48, color: colors.primary),
              const SizedBox(height: 14),
              Text(
                controller.error ?? 'تعذّر فتح نص القرآن.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.busy ? null : controller.load,
                icon: const Icon(Icons.download_rounded),
                label: const Text('إعادة المحاولة'),
              ),
              const SizedBox(height: 10),
              const Text(
                'يحتاج التنزيل الأول إلى اتصال بالإنترنت.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reader(
    BuildContext context,
    QuranData data,
    QuranAyah current,
    int design,
    double azkarFontSize,
    String? error,
  ) {
    return Column(
      children: [
        if (error != null)
          MaterialBanner(
            content: Text(error),
            actions: [
              TextButton(
                onPressed: _quran.refreshing ? null : _quran.refresh,
                child: const Text('تحديث'),
              ),
            ],
          ),
        Expanded(
          child: design == 2
              ? _ayahReader(data, azkarFontSize)
              : _pageReader(data, current, azkarFontSize),
        ),
        if (design == 2)
          _stepControls(data, current)
        else
          _pageControls(data, current),
      ],
    );
  }

  Widget _ayahReader(QuranData data, double fontSize) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PageView.builder(
      controller: _ayahPager,
      itemCount: data.ayahs.length,
      onPageChanged: (index) {
        final number = index + 1;
        if (number != _currentAyahNumber) {
          setState(() => _currentAyahNumber = number);
          context.read<AppState>().saveQuranPosition(number);
        }
      },
      itemBuilder: (context, index) {
        final visibleAyah = data.ayahs[index];
        final surah = data.surah(visibleAyah.surahNumber);
        return ListView(
      key: const ValueKey('quran-ayah-design'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        _surahHeading(surah, visibleAyah),
        const SizedBox(height: 16),
        GlassCard(
          reading: true,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: Column(
              children: [
                Text(
                  'آية ${visibleAyah.numberInSurah}',
                  style: TextStyle(color: colors.primary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  visibleAyah.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: fontSize,
                    height: 2,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الجزء ${visibleAyah.juz} · الصفحة ${visibleAyah.page}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'اسحب يمينًا أو يسارًا للانتقال بين الآيات.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      ],
        );
      },
    );
  }

  Widget _pageReader(QuranData data, QuranAyah current, double fontSize) {
    final ayahs = data.page(current.page);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      key: const ValueKey('quran-page-design'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      children: [
        _surahHeading(data.surah(current.surahNumber), current),
        const SizedBox(height: 12),
        GlassCard(
          reading: true,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                for (var i = 0; i < ayahs.length; i++) ...[
                  if (i == 0 ||
                      ayahs[i - 1].surahNumber != ayahs[i].surahNumber) ...[
                    if (i > 0) const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        data.surah(ayahs[i].surahNumber).name,
                        style: TextStyle(
                          color: colors.primary,
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  _pageAyah(ayahs[i], fontSize, colors),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageAyah(QuranAyah ayah, double fontSize, ColorScheme colors) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _setAyah(ayah.number),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsetsDirectional.only(end: 10, top: 5),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _arabicDigits(ayah.numberInSurah),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    ayah.text,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: fontSize - 3,
                      height: 2,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _surahHeading(QuranSurah surah, QuranAyah ayah) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: colors.primary),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'} · '
                    '${surah.numberOfAyahs} آيات',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'ص ${_arabicDigits(ayah.page)}',
              style: TextStyle(color: colors.primary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepControls(QuranData data, QuranAyah ayah) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.surah(ayah.surahNumber).name} · آية ${ayah.numberInSurah}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'الآية السابقة',
                    onPressed: ayah.number > 1
                        ? () => _setAyah(ayah.number - 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  IconButton(
                    tooltip: 'الآية التالية',
                    onPressed: ayah.number < data.ayahs.length
                        ? () => _setAyah(ayah.number + 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageControls(QuranData data, QuranAyah ayah) {
    final colors = Theme.of(context).colorScheme;
    final progress = ayah.page / QuranData.pageCount;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 7, 16, 10),
      child: GlassCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.bookmark_added_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'موضعك محفوظ · ${data.surah(ayah.surahNumber).name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'صفحة ${_arabicDigits(ayah.page)} / ${_arabicDigits(QuranData.pageCount)}',
                    style: TextStyle(color: colors.primary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                borderRadius: BorderRadius.circular(8),
                semanticsLabel: 'التقدم في صفحات المصحف',
                semanticsValue: '${(progress * 100).round()} بالمئة',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: ayah.page > 1 ? () => _movePage(data, -1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('السابق'),
                  ),
                  TextButton.icon(
                    onPressed: ayah.page < QuranData.pageCount
                        ? () => _movePage(data, 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('التالي'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _arabicDigits(int value) => value
      .toString()
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');
}

class QuranSurahPicker extends StatefulWidget {
  const QuranSurahPicker({super.key, required this.surahs});

  final List<QuranSurah> surahs;

  @override
  State<QuranSurahPicker> createState() => _QuranSurahPickerState();
}

class _QuranSurahPickerState extends State<QuranSurahPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _search.text.trim();
    final surahs = widget.surahs.where((surah) {
      return query.isEmpty ||
          surah.name.contains(query) ||
          surah.englishName.toLowerCase().contains(query.toLowerCase());
    }).toList(growable: false);
    return Container(
      height: MediaQuery.sizeOf(context).height * .8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 17, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'اختر السورة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن سورة',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: surahs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  return ListTile(
                    minVerticalPadding: 8,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.primary,
                      child: Text(_QuranScreenState._arabicDigits(surah.number)),
                    ),
                    title: Text(surah.name),
                    subtitle: Text('${surah.numberOfAyahs} آيات'),
                    trailing: const Icon(Icons.arrow_back_rounded, size: 18),
                    onTap: () => Navigator.pop(context, surah.number),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
