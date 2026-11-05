import 'zikr.dart';

String dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

/// Stores completed taps, so counters can be clamped if bundled content changes.
class DailyProgress {
  DailyProgress(this.day, [Map<String, int>? counts]) : counts = counts ?? {};
  String day;
  final Map<String, int> counts;

  bool resetIfNewDay(DateTime now) {
    if (day == dayKey(now)) return false;
    day = dayKey(now);
    counts.clear();
    return true;
  }

  String key(AzkarPeriod period, Zikr zikr) => '${period.name}:${zikr.id}';
  int completed(AzkarPeriod period, Zikr zikr) =>
      (counts[key(period, zikr)] ?? 0).clamp(0, zikr.progressTarget);
  int remaining(AzkarPeriod period, Zikr zikr) =>
      zikr.progressTarget - completed(period, zikr);
  bool tap(AzkarPeriod period, Zikr zikr) {
    final value = completed(period, zikr);
    if (value >= zikr.progressTarget) return false;
    counts[key(period, zikr)] = value + 1;
    return value + 1 == zikr.progressTarget;
  }

  void reset(AzkarPeriod period, Zikr zikr) => counts.remove(key(period, zikr));
  double fraction(AzkarPeriod period, List<Zikr> items) {
    final total = items.fold<int>(0, (sum, z) => sum + z.progressTarget);
    return total == 0
        ? 0
        : items.fold<int>(0, (sum, z) => sum + completed(period, z)) / total;
  }
}
