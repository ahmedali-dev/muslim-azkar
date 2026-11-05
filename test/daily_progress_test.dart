import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_azkar/models/daily_progress.dart';
import 'package:muslim_azkar/models/zikr.dart';

void main() {
  const zikr = Zikr(id: 1, text: 'ذكر', repeat: 3);
  const p = AzkarPeriod.morning;
  test('counter decrements to zero and only completes once', () {
    final progress = DailyProgress(dayKey(DateTime(2026, 11, 2)));
    expect(progress.remaining(p, zikr), 3);
    expect(progress.tap(p, zikr), false);
    expect(progress.remaining(p, zikr), 2);
    expect(progress.tap(p, zikr), false);
    expect(progress.tap(p, zikr), true);
    expect(progress.remaining(p, zikr), 0);
    expect(progress.tap(p, zikr), false);
    expect(progress.completed(p, zikr), 3);
    progress.reset(p, zikr);
    expect(progress.remaining(p, zikr), 3);
  });
  test('daily reset crosses midnight and keeps periods independent', () {
    final progress = DailyProgress(dayKey(DateTime(2026, 11, 2, 23, 59)));
    progress.tap(p, zikr);
    expect(progress.remaining(AzkarPeriod.evening, zikr), 3);
    expect(progress.resetIfNewDay(DateTime(2026, 11, 2, 23, 59, 59)), false);
    expect(progress.remaining(p, zikr), 2);
    expect(progress.resetIfNewDay(DateTime(2026, 11, 3)), true);
    expect(progress.counts, isEmpty);
    expect(progress.remaining(p, zikr), 3);
  });
  test('progress is weighted by repetitions and old values are clamped', () {
    final progress = DailyProgress('today', {'morning:1': 999});
    const other = Zikr(id: 2, text: 'ذكر', repeat: 1);
    expect(progress.remaining(p, zikr), 0);
    expect(progress.fraction(p, [zikr, other]), .75);
    progress.tap(p, other);
    expect(progress.fraction(p, [zikr, other]), 1);
  });
  test(
    'a zero source count is marked as read without inventing repetitions',
    () {
      const reading = Zikr(id: 1, text: 'نص للقراءة', repeat: 0);
      final progress = DailyProgress('today');
      expect(reading.repeat, 0);
      expect(reading.hasRepetitions, false);
      expect(progress.fraction(AzkarPeriod.duaMerit, [reading]), 0);
      expect(progress.tap(AzkarPeriod.duaMerit, reading), true);
      expect(progress.remaining(AzkarPeriod.duaMerit, reading), 0);
      expect(progress.fraction(AzkarPeriod.duaMerit, [reading]), 1);
      expect(progress.tap(AzkarPeriod.duaMerit, reading), false);
      expect(progress.remaining(AzkarPeriod.food, reading), 1);
    },
  );
}
