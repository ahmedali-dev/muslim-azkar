import 'package:flutter/material.dart';

/// Shared surface retained across screens; flat fills avoid expensive blur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.gradient,
    this.reading = false,
  });
  final Widget child;
  final double radius;
  final Gradient? gradient;
  final bool reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: gradient == null
              ? (dark && !reading
                    ? const Color(0xFF192B2C)
                    : theme.colorScheme.surface)
              : null,
          gradient: gradient,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: dark ? .65 : 1,
            ),
          ),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(4),
    this.reading = false,
    this.gradient,
  });
  final Widget child;
  final EdgeInsetsGeometry margin;
  final bool reading;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: GlassSurface(reading: reading, gradient: gradient, child: child),
  );
}

class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
}
