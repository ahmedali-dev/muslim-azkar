import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/zikr.dart';
import '../services/native_bridge.dart';
import '../services/share_image_renderer.dart';

class ShareImageScreen extends StatefulWidget {
  const ShareImageScreen({super.key, required this.zikr, required this.period});
  final Zikr zikr;
  final AzkarPeriod period;
  @override
  State<ShareImageScreen> createState() => _ShareImageScreenState();
}

class _ShareImageScreenState extends State<ShareImageScreen> {
  bool? _dark;
  bool _portrait = true;
  bool _busy = false;
  bool _cancelled = false;
  int _page = 0;
  int _generation = 0;
  int _exported = 0;
  List<String> _pages = [];
  Uint8List? _preview;
  String? _error;
  ShareImageStyle get _style =>
      ShareImageStyle(dark: _dark ?? false, portrait: _portrait);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dark == null) {
      _dark = Theme.of(context).brightness == Brightness.dark;
      _refresh();
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancelled = true;
    super.dispose();
  }

  Future<Uint8List> _render(int page) => ShareImageRenderer.render(
    text: _pages[page],
    category: widget.period.title,
    repeat: widget.zikr.repeat,
    style: _style,
    page: page + 1,
    pageCount: _pages.length,
  );

  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _preview = null;
      _error = null;
    });
    try {
      _pages = ShareImageRenderer.paginate(widget.zikr.text, _style);
      _page = _page.clamp(0, _pages.length - 1);
      final bytes = await _render(_page);
      if (mounted && generation == _generation) {
        setState(() => _preview = bytes);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'تعذّر تجهيز الصورة. حاول مرة أخرى.');
      }
    }
  }

  Future<void> _share(bool all) async {
    if (_busy || _preview == null) return;
    setState(() {
      _busy = true;
      _cancelled = false;
      _exported = 0;
    });
    final files = <String>[];
    Directory? session;
    try {
      final root = await NativeBridge.shareDirectory();
      session = await Directory(
        '$root/${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final indices = all ? List.generate(_pages.length, (i) => i) : [_page];
      for (final index in indices) {
        if (_cancelled || !mounted) break;
        final bytes = index == _page ? _preview! : await _render(index);
        if (_cancelled || !mounted) break;
        final file = File('${session.path}/zikr-${index + 1}.png');
        await file.writeAsBytes(bytes, flush: true);
        files.add(file.path);
        if (mounted) setState(() => _exported++);
      }
      if (!_cancelled && mounted && files.isNotEmpty) {
        await NativeBridge.shareImages(files);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّرت مشاركة الصورة. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (_cancelled && session != null) {
        try {
          await session.delete(recursive: true);
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة كصورة')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ذكرٌ جميل، وأثرٌ يصل إلى غيرك',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Amiri', fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'صورة جاهزة لواتساب وإكس وفيسبوك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('سكينة'),
                              selected: _dark == false,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                      _dark = false;
                                      _refresh();
                                    },
                            ),
                            ChoiceChip(
                              label: const Text('ليل'),
                              selected: _dark == true,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                      _dark = true;
                                      _refresh();
                                    },
                            ),
                            ChoiceChip(
                              label: const Text('طولي'),
                              selected: _portrait,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                      _portrait = true;
                                      _page = 0;
                                      _refresh();
                                    },
                            ),
                            ChoiceChip(
                              label: const Text('مربع'),
                              selected: !_portrait,
                              onSelected: _busy
                                  ? null
                                  : (_) {
                                      _portrait = false;
                                      _page = 0;
                                      _refresh();
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(_error!),
                                TextButton(
                                  onPressed: _refresh,
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          )
                        else if (_preview == null)
                          const SizedBox(
                            height: 260,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Semantics(
                            label:
                                'معاينة صورة الذكر، الصفحة ${_page + 1} من ${_pages.length}',
                            image: true,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                _preview!,
                                key: const ValueKey('shareImagePreview'),
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        if (_pages.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'الصورة السابقة',
                                onPressed: _busy || _page == 0
                                    ? null
                                    : () {
                                        _page--;
                                        _refresh();
                                      },
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                              Text(
                                '${_page + 1} / ${_pages.length}',
                                textDirection: TextDirection.ltr,
                              ),
                              IconButton(
                                tooltip: 'الصورة التالية',
                                onPressed: _busy || _page >= _pages.length - 1
                                    ? null
                                    : () {
                                        _page++;
                                        _refresh();
                                      },
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                            ],
                          ),
                          const Text(
                            'النص طويل؛ قُسّم على صور متتابعة دون حذف أي كلمة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_busy) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'تجهيز الصور: $_exported',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => setState(() => _cancelled = true),
                          child: const Text('إلغاء'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          key: const ValueKey('shareImageButton'),
                          onPressed: _preview == null
                              ? null
                              : () => _share(false),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(
                            _pages.length > 1
                                ? 'مشاركة هذه الصورة'
                                : 'مشاركة الصورة',
                          ),
                        ),
                        if (_pages.length > 1)
                          TextButton(
                            onPressed: _preview == null
                                ? null
                                : () => _share(true),
                            child: const Text('مشاركة جميع الصور'),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
