import 'package:flutter/material.dart';
import 'zikr.dart';

class AppSettings {
  AppSettings({
    this.fontLevel = 1,
    this.themeMode = ThemeMode.system,
    this.vibration = true,
    this.morningEnabled = false,
    this.eveningEnabled = false,
    this.morningMinutes = 330,
    this.eveningMinutes = 990,
    this.asrMinutes = 960,
  });

  int fontLevel;
  ThemeMode themeMode;
  bool vibration;
  bool morningEnabled;
  bool eveningEnabled;
  int morningMinutes;
  int eveningMinutes;
  int asrMinutes;
  double get fontSize => [25.0, 30.0, 36.0][fontLevel];
  bool enabled(AzkarPeriod p) => switch (p) {
    AzkarPeriod.morning => morningEnabled,
    AzkarPeriod.evening => eveningEnabled,
    _ => false,
  };
  int minutes(AzkarPeriod p) => switch (p) {
    AzkarPeriod.morning => morningMinutes,
    AzkarPeriod.evening => eveningMinutes,
    _ => throw ArgumentError('This category has no daily reminder.'),
  };
  void setReminder(AzkarPeriod p, bool enabled, int minutes) {
    if (!p.supportsReminder) {
      throw ArgumentError('Unsupported reminder category.');
    }
    if (p == AzkarPeriod.morning) {
      morningEnabled = enabled;
      morningMinutes = minutes;
    } else {
      eveningEnabled = enabled;
      eveningMinutes = minutes;
    }
  }

  Map<String, dynamic> toJson() => {
    'fontLevel': fontLevel,
    'asrMinutes': asrMinutes,
    'theme': themeMode.name,
    'vibration': vibration,
    'morningEnabled': morningEnabled,
    'eveningEnabled': eveningEnabled,
    'morningMinutes': morningMinutes,
    'eveningMinutes': eveningMinutes,
  };
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    asrMinutes: ((j['asrMinutes'] as int?) ?? 960).clamp(720, 1439),
    fontLevel: ((j['fontLevel'] as int?) ?? 1).clamp(0, 2),
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == j['theme'],
      orElse: () => ThemeMode.system,
    ),
    vibration: j['vibration'] as bool? ?? true,
    morningEnabled: j['morningEnabled'] as bool? ?? false,
    eveningEnabled: j['eveningEnabled'] as bool? ?? false,
    morningMinutes: ((j['morningMinutes'] as int?) ?? 330).clamp(0, 1439),
    eveningMinutes: ((j['eveningMinutes'] as int?) ?? 990).clamp(0, 1439),
  );
}
