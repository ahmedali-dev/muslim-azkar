import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small vector ornament: no image download or oversized bitmap assets.
class Ornament extends StatelessWidget {
  const Ornament({
    super.key,
    this.color = const Color(0xFF1F7A6D),
    this.size = 100,
  });
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _OrnamentPainter(color),
    ),
  );
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = size.width * .34;
    for (var i = 0; i < 2; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.65,
            height: r * 1.65,
          ),
          Radius.circular(r * .12),
        ),
        p,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * .48, p);
    canvas.drawCircle(Offset.zero, r * .1, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
