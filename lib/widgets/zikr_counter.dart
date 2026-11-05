import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sakina's tasbih beads and Layl's moon orbit, drawn only when progress changes.
class ZikrCounter extends StatelessWidget {
  const ZikrCounter({
    super.key,
    required this.remaining,
    required this.total,
    required this.readingOnly,
    required this.onPressed,
  });
  final int remaining;
  final int total;
  final bool readingOnly;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFD8EBD9) : const Color(0xFF275740);
    return SizedBox.square(
      dimension: 80,
      child: CustomPaint(
        painter: _CounterPainter(
          dark,
          ((total - remaining) / total).clamp(0, 1),
        ),
        child: FilledButton(
          key: ValueKey(dark ? 'layl-counter' : 'sakina-counter'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: ink,
            disabledForegroundColor: ink,
            shape: const CircleBorder(),
            minimumSize: const Size(80, 80),
          ),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: remaining == 0 || readingOnly
                ? Icon(
                    remaining == 0
                        ? Icons.check_rounded
                        : Icons.done_all_rounded,
                    size: 27,
                  )
                : FittedBox(
                    key: ValueKey(remaining),
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$remaining',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CounterPainter extends CustomPainter {
  const _CounterPainter(this.dark, this.progress);
  final bool dark;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = Rect.fromCircle(center: c, radius: 37);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      c,
      31,
      Paint()..color = dark ? const Color(0xFF294A41) : const Color(0xFFE3EDDA),
    );
    canvas.drawCircle(
      c,
      31,
      stroke..color = dark ? const Color(0xFF719B81) : const Color(0xFFC3D4B4),
    );
    if (dark) {
      canvas.drawOval(ring, stroke..color = const Color(0xFF537563));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-math.pi / 5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 77, height: 47),
        stroke..color = const Color(0xFF456657),
      );
      canvas.restore();
      final angle = -math.pi / 3 + progress * math.pi * 1.6;
      final moon = c + Offset(math.cos(angle), math.sin(angle)) * 37;
      final path = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 5)),
        Path()..addOval(
          Rect.fromCircle(center: moon + const Offset(3, -2), radius: 4.5),
        ),
      );
      canvas.drawPath(path, Paint()..color = const Color(0xFFC4DCAA));
      canvas.drawCircle(
        c + const Offset(-32, 24),
        2,
        Paint()..color = const Color(0xFFADC9A8),
      );
    } else {
      for (var i = 0; i < 36; i++) {
        canvas.drawArc(
          ring,
          -math.pi / 2 + i * math.pi / 18,
          .045,
          false,
          stroke..color = const Color(0xFFB0C7A5),
        );
      }
      canvas.drawArc(
        ring,
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF40775A),
      );
      for (var i = 0; i < 3; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 3;
        final bead = c + Offset(math.cos(angle), math.sin(angle)) * 37;
        canvas.drawCircle(bead, 4.5, Paint()..color = const Color(0xFFF5F8F3));
        canvas.drawCircle(
          bead,
          3,
          Paint()
            ..color = progress >= (i + 1) / 3
                ? const Color(0xFF224F37)
                : const Color(0xFF6E925C),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CounterPainter oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.progress != progress;
}
