import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/zikr.dart';
import '../providers/app_state.dart';
import '../services/native_bridge.dart';
import '../widgets/zikr_counter.dart';
import 'completion_screen.dart';
import 'share_image_screen.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key, required this.period});
  final AzkarPeriod period;
  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  late PageController _controller;
  final _textControllers = <int, ScrollController>{};
  ScrollController _textController(int id) =>
      _textControllers.putIfAbsent(id, () => ScrollController());
  late int _index;
  late String _day;
  bool _review = false;
  bool _advancing = false;
  final Set<int> _shownEncouragements = {};
  static const _encouragements = <int, String>{
    25: 'كلّ خطوة تقرّبك من إتمام وردك.',
    50: 'واصل على مهل، فأجمل الورد ما حضر فيه القلب.',
    75: 'خذ لحظة هدوء، ثم أكمل ما بقي بقلب مطمئن.',
  };
  static const _encouragementTitles = <int, String>{
    25: 'أحسنت، بدأت الطريق',
    50: 'ما شاء الله، أنجزت نصف الورد',
    75: 'لم يبقَ إلا القليل',
  };
  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    state.ensureToday();
    _day = state.progress.day;
    _index = state.firstIncomplete(widget.period);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _returnToStart(bool review) {
    _controller.jumpToPage(0);
    setState(() {
      _review = review;
      _index = 0;
    });
  }

  Future<void> _tap(Zikr z) async {
    final state = context.read<AppState>();
    if (_advancing || state.progress.remaining(widget.period, z) == 0) return;
    final previousProgress = state.fraction(widget.period);
    if (state.settings.vibration) {
      HapticFeedback.lightImpact();
    }
    _review = false;
    final finished = state.tap(widget.period, z);
    await _showEncouragement(previousProgress, state.fraction(widget.period));
    if (!mounted || !finished) return;
    _advancing = true;
    final current = _index;
    final day = state.progress.day;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    // A swipe, reset, or midnight rollover invalidates a pending advance.
    if (day == state.progress.day &&
        current == _index &&
        state.progress.remaining(widget.period, z) == 0 &&
        !state.isComplete(widget.period)) {
      final items = state.content[widget.period]!;
      var next = items.indexWhere(
        (item) =>
            item.id > z.id && state.progress.remaining(widget.period, item) > 0,
      );
      if (next < 0) next = state.firstIncomplete(widget.period);
      if (_controller.hasClients) {
        await _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
        );
      }
    }
    if (mounted) setState(() => _advancing = false);
  }

  Future<void> _showEncouragement(double before, double after) async {
    final milestone = _encouragements.keys.firstWhere(
      (value) =>
          before < value / 100 &&
          after >= value / 100 &&
          !_shownEncouragements.contains(value),
      orElse: () => 0,
    );
    if (milestone == 0 || !mounted || after >= 1) return;
    _shownEncouragements.add(milestone);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .2),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 25,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _encouragementTitles[milestone]!,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _encouragements[milestone]!,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 15,
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'رسالة تشجيع · تقدّم $milestone٪',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('متابعة الذكر'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.content[widget.period]!;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    if (_day != state.progress.day) {
      _day = state.progress.day;
      _review = false;
      _shownEncouragements.clear();
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
    final complete = state.isComplete(widget.period) && !_review;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const GlassSurface(radius: 0, child: SizedBox.expand()),
        title: Text(widget.period.title),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Text(
                complete ? 'اكتملت' : '${_index + 1} / ${items.length}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: LinearProgressIndicator(
                value: state.fraction(widget.period),
                color: color,
                borderRadius: BorderRadius.circular(8),
                minHeight: 4,
                semanticsLabel: 'التقدم في أذكار اليوم',
                semanticsValue:
                    '${(state.fraction(widget.period) * 100).round()} بالمئة',
              ),
            ),
            if (state.storageError != null)
              Text(
                state.storageError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            Expanded(
              child: Stack(
                children: [
                  Offstage(
                    offstage: complete,
                    child: PageView.builder(
                      key: const ValueKey("reader"),
                      controller: _controller,
                      itemCount: items.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final z = items[i];
                        final remaining = state.progress.remaining(
                          widget.period,
                          z,
                        );
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final minimum =
                                440.0 *
                                MediaQuery.textScalerOf(
                                  context,
                                ).scale(1).clamp(1.0, 1.5);
                            return SingleChildScrollView(
                              primary: false,
                              child: SizedBox(
                                height: constraints.maxHeight < minimum
                                    ? minimum
                                    : constraints.maxHeight,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 760,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        12,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: GlassCard(
                                              reading: true,
                                              margin: EdgeInsets.zero,
                                              child: Scrollbar(
                                                controller: _textController(
                                                  z.id,
                                                ),
                                                child: SingleChildScrollView(
                                                  controller: _textController(
                                                    z.id,
                                                  ),
                                                  primary: false,
                                                  key: PageStorageKey(
                                                    '${widget.period.name}-${z.id}',
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    24,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Text(
                                                        'النص ${i + 1}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      SelectableText(
                                                        z.text,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Amiri',
                                                          fontSize: state
                                                              .settings
                                                              .fontSize,
                                                          height: 1.9,
                                                        ),
                                                      ),
                                                      if (z
                                                          .source
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 24,
                                                        ),
                                                        Text(
                                                          z.source,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontSize: 15,
                                                            height: 1.7,
                                                          ),
                                                        ),
                                                      ],
                                                      if (z
                                                          .virtue
                                                          .isNotEmpty) ...[
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 16,
                                                              ),
                                                          child: Divider(),
                                                        ),
                                                        const Text(
                                                          'فضل الذكر',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          z.virtue,
                                                          style: TextStyle(
                                                            fontFamily: 'Amiri',
                                                            fontSize: 20,
                                                            height: 1.8,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 8,
                                            children: [
                                              IconButton(
                                                tooltip: 'نسخ الذكر',
                                                icon: const Icon(
                                                  Icons.copy_rounded,
                                                ),
                                                onPressed: () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(text: z.text),
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'تم نسخ الذكر',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'مشاركة الذكر',
                                                icon: const Icon(
                                                  Icons.share_rounded,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await NativeBridge.share(
                                                      z.text,
                                                    );
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'تعذّرت المشاركة',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'مشاركة كصورة',
                                                icon: const Icon(
                                                  Icons.image_outlined,
                                                ),
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        ShareImageScreen(
                                                          zikr: z,
                                                          period: widget.period,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'إعادة عدّ هذا الذكر',
                                                icon: const Icon(
                                                  Icons.restart_alt_rounded,
                                                ),
                                                onPressed: () => state.reset(
                                                  widget.period,
                                                  z,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Semantics(
                                            button: true,
                                            liveRegion: true,
                                            label: remaining == 0
                                                ? 'اكتمل الذكر'
                                                : (z.hasRepetitions
                                                      ? 'عدّ الذكر، المتبقي $remaining من ${z.repeat}'
                                                      : 'تمييز النص كمقروء'),
                                            excludeSemantics: true,
                                            child: ZikrCounter(
                                              remaining: remaining,
                                              total: z.progressTarget,
                                              readingOnly: !z.hasRepetitions,
                                              onPressed: remaining == 0
                                                  ? null
                                                  : () => _tap(z),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            remaining == 0
                                                ? 'اكتمل، تقبّل الله'
                                                : (z.hasRepetitions
                                                      ? 'اضغط مع كل تكرار'
                                                      : 'اضغط بعد إتمام القراءة'),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (complete)
                    CompletionScreen(
                      key: const ValueKey('complete'),
                      onReview: () => _returnToStart(true),
                      onRestart: () {
                        state.restart(widget.period);
                        _shownEncouragements.clear();
                        _returnToStart(false);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
