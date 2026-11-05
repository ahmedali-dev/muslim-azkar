import 'package:flutter/material.dart';
import '../models/zikr.dart';
import 'glass_surface.dart';

class PeriodCard extends StatelessWidget {
  const PeriodCard({
    super.key,
    required this.period,
    required this.progress,
    required this.highlighted,
    required this.onTap,
    required this.count,
    this.featured = true,
  });
  final AzkarPeriod period;
  final double progress;
  final bool highlighted;
  final VoidCallback onTap;
  final int count;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final morning = period == AzkarPeriod.morning;
    final ink = theme.colorScheme.onSurface;
    final percent = (progress * 100).round();
    final accent = dark ? const Color(0xFFAACCB3) : const Color(0xFF64894D);
    final icon = Icon(
      morning ? Icons.wb_sunny_rounded : Icons.nightlight_round,
      color: accent,
      size: featured ? 34 : 28,
    );
    final meter = LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      color: accent,
      backgroundColor: accent.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(8),
    );
    return Semantics(
      button: true,
      label: '${period.title}، التقدم $percent بالمئة',
      excludeSemantics: true,
      child: GlassSurface(
        gradient: featured
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xFF294D43), const Color(0xFF213B37)]
                    : [const Color(0xFFE4EEDF), const Color(0xFFEAF1E3)],
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(featured ? 22 : 18),
            child: featured
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          icon,
                          const Spacer(),
                          if (highlighted)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF395B4C)
                                      : const Color(0xFFF5F9F0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'وقتك للذكر',
                                  style: TextStyle(color: ink, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        period.title,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 30,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        morning ? 'بدايةٌ يملؤها النور' : 'حان وقت السكينة',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$count ذكرًا',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '$percent٪',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      meter,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (highlighted) ...[
                              Text(
                                'وقتك للذكر',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              period.title,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$count ذكرًا • $percent٪ من ورد اليوم',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            meter,
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      icon,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
