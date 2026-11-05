import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ShareImageStyle {
  const ShareImageStyle({this.dark = false, this.portrait = true});
  final bool dark;
  final bool portrait;
  Size get size => Size(1080, portrait ? 1350 : 1080);
  double get textHeight => size.height - 474;
}

/// Splits only at shaped line boundaries; joining pages reproduces the source.
abstract final class ShareImageRenderer {
  static const textWidth = 804.0;
  static TextPainter _text(String value, ShareImageStyle style) => TextPainter(
    text: TextSpan(
      text: value,
      style: const TextStyle(fontFamily: 'Amiri', fontSize: 54, height: 1.85),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
  )..layout(minWidth: textWidth, maxWidth: textWidth);

  static List<String> paginate(String text, ShareImageStyle style) {
    final pages = <String>[];
    var remaining = text;
    while (remaining.isNotEmpty) {
      final painter = _text(remaining, style);
      try {
        if (painter.height <= style.textHeight) {
          pages.add(remaining);
          break;
        }
        final lines = painter.computeLineMetrics();
        final fitting = lines
            .where((line) => line.baseline + line.descent <= style.textHeight)
            .toList();
        final line = fitting.isEmpty ? lines.first : fitting.last;
        final position = painter.getPositionForOffset(
          Offset(textWidth / 2, line.baseline - line.ascent / 2),
        );
        final end = painter.getLineBoundary(position).end;
        if (end <= 0 || end >= remaining.length) {
          throw StateError('Could not paginate the source text');
        }
        pages.add(remaining.substring(0, end));
        remaining = remaining.substring(end);
      } finally {
        painter.dispose();
      }
    }
    return pages.isEmpty ? [''] : pages;
  }

  static Future<Uint8List> render({
    required String text,
    required String category,
    required int repeat,
    required ShareImageStyle style,
    required int page,
    required int pageCount,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = style.size;
    final dark = style.dark;
    final ink = dark ? const Color(0xFFE4EDE8) : const Color(0xFF173E31);
    final accent = dark ? const Color(0xFF94C7B0) : const Color(0xFF52794E);
    canvas.drawColor(
      dark ? const Color(0xFF142127) : const Color(0xFFF5F8F3),
      BlendMode.src,
    );
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(56, 56, size.width - 112, size.height - 112),
      const Radius.circular(48),
    );
    canvas.drawRRect(
      card,
      Paint()..color = dark ? const Color(0xFF1C3032) : const Color(0xFFFFFEFA),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = dark ? const Color(0xFF3C594D) : const Color(0xFFD4E0CC),
    );
    // Quiet geometric details are painted vectors; text stays the focal point.
    for (final offset in [
      const Offset(112, 112),
      Offset(size.width - 112, size.height - 112),
    ]) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-13, -13, 26, 26),
          const Radius.circular(3),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: .6),
      );
      canvas.restore();
    }
    void label(
      String value,
      double y, {
      double fontSize = 28,
      Color? color,
      String font = 'Tajawal',
      double width = 804,
    }) {
      final p = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: font,
            fontSize: fontSize,
            color: color ?? ink,
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout(maxWidth: width);
      p.paint(canvas, Offset((size.width - p.width) / 2, y));
      p.dispose();
    }

    label(
      'ذِكْرٌ وَطُمَأْنِينَة',
      100,
      fontSize: 32,
      color: accent,
      font: 'Amiri',
    );
    label(category, 163, fontSize: 30, color: accent);
    canvas.drawLine(
      const Offset(414, 226),
      const Offset(666, 226),
      Paint()
        ..color = accent.withValues(alpha: .35)
        ..strokeWidth = 1.5,
    );
    final paragraph = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 54,
          height: 1.85,
          color: ink,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(minWidth: textWidth, maxWidth: textWidth);
    paragraph.paint(
      canvas,
      Offset(
        (size.width - textWidth) / 2,
        264 + (style.textHeight - paragraph.height) / 2,
      ),
    );
    paragraph.dispose();
    final bottom = size.height - 185;
    if (repeat > 0) {
      label('التكرار: $repeat', bottom, fontSize: 24, color: accent);
    }
    label('أذكار المسلم', size.height - 132, fontSize: 25, color: accent);
    label('المصدر: إسلام بوك', size.height - 92, fontSize: 18, color: accent);
    if (pageCount > 1) {
      final number = TextPainter(
        text: TextSpan(
          text: '$page / $pageCount',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 21, color: accent),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(
        canvas,
        Offset(size.width - 172 - number.width, size.height - 118),
      );
      number.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally {
      image.dispose();
    }
  }
}
