import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_azkar/models/zikr.dart';
import 'package:muslim_azkar/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'relaunch restores counters; next day resets progress but keeps settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026, 11, 2, 23, 59);
      const z = Zikr(id: 1, text: 'ذكر', repeat: 3);
      final data = {
        AzkarPeriod.morning: [z],
        AzkarPeriod.evening: [z],
      };
      final state = AppState(prefs, data, clock: () => now);
      state.tap(AzkarPeriod.morning, z);
      state.updateSettings((s) => s.fontLevel = 2);
      await state.flush();
      state.dispose();
      final restored = AppState(prefs, data, clock: () => now);
      expect(restored.progress.remaining(AzkarPeriod.morning, z), 2);
      expect(restored.settings.fontLevel, 2);
      now = DateTime(2026, 11, 3);
      expect(restored.ensureToday(), true);
      await restored.flush();
      expect(restored.progress.remaining(AzkarPeriod.morning, z), 3);
      expect(restored.settings.fontLevel, 2);
      expect(
        (jsonDecode(prefs.getString('progress')!) as Map)['counts'],
        isEmpty,
      );
      restored.dispose();
    },
  );
}
