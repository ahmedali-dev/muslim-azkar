import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/daily_progress.dart';
import '../models/zikr.dart';

class AppState extends ChangeNotifier {
  AppState(this.prefs, this.content, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    settings = _readSettings();
    progress = _readProgress();
    ensureToday();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ensureToday();
      final now = _clock();
      if (now.minute != _lastMinute) {
        _lastMinute = now.minute;
        notifyListeners();
      }
    });
  }
  final SharedPreferences prefs;
  final Map<AzkarPeriod, List<Zikr>> content;
  final DateTime Function() _clock;
  late final Timer _timer;
  late AppSettings settings;
  late DailyProgress progress;
  int _lastMinute = -1;
  Future<void> _pendingWrite = Future.value();
  String? storageError;
  DateTime get now => _clock();

  AppSettings _readSettings() {
    try {
      return AppSettings.fromJson(
        jsonDecode(prefs.getString('settings') ?? '{}') as Map<String, dynamic>,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  DailyProgress _readProgress() {
    try {
      final j =
          jsonDecode(prefs.getString('progress') ?? '{}')
              as Map<String, dynamic>;
      return DailyProgress(
        j['day'] as String? ?? dayKey(now),
        (j['counts'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v as int),
        ),
      );
    } catch (_) {
      return DailyProgress(dayKey(now));
    }
  }

  // Serialize disk writes, including rapid taps immediately before midnight.
  void _save(String key, String snapshot) {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        if (!await prefs.setString(key, snapshot)) {
          throw StateError('Could not persist preferences');
        }
        if (storageError != null) {
          storageError = null;
          notifyListeners();
        }
      } catch (_) {
        storageError = 'تعذّر حفظ التقدم. تحقّق من مساحة التخزين.';
        notifyListeners();
      }
    });
  }

  Future<void> flush() => _pendingWrite;
  void _saveProgress() => _save(
    'progress',
    jsonEncode({
      'day': progress.day,
      'counts': Map<String, int>.of(progress.counts),
    }),
  );
  bool ensureToday() {
    if (!progress.resetIfNewDay(now)) return false;
    _saveProgress();
    notifyListeners();
    return true;
  }

  bool tap(AzkarPeriod p, Zikr z) {
    ensureToday();
    final finished = progress.tap(p, z);
    _saveProgress();
    notifyListeners();
    return finished;
  }

  void reset(AzkarPeriod p, Zikr z) {
    ensureToday();
    progress.reset(p, z);
    _saveProgress();
    notifyListeners();
  }

  void restart(AzkarPeriod p) {
    ensureToday();
    for (final z in content[p]!) {
      progress.reset(p, z);
    }
    _saveProgress();
    notifyListeners();
  }

  double fraction(AzkarPeriod p) => progress.fraction(p, content[p]!);
  bool isComplete(AzkarPeriod p) =>
      content[p]!.every((z) => progress.remaining(p, z) == 0);
  int firstIncomplete(AzkarPeriod p) {
    final index = content[p]!.indexWhere((z) => progress.remaining(p, z) > 0);
    return index < 0 ? 0 : index;
  }

  void updateSettings(void Function(AppSettings) change) {
    change(settings);
    _save('settings', jsonEncode(settings.toJson()));
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
