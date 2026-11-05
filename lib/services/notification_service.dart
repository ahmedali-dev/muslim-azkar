import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_settings.dart';
import '../models/zikr.dart';
import 'native_bridge.dart';

enum ReminderResult { exact, approximate, denied }

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  void Function(AzkarPeriod)? onOpen;
  AzkarPeriod? initialPeriod;
  bool available = false;

  AzkarPeriod? _period(String? payload) {
    for (final p in AzkarPeriod.reminderPeriods) {
      if (p.name == payload) return p;
    }
    return null;
  }

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await refreshTimezone();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final p = _period(response.payload);
        if (p != null) onOpen?.call(p);
      },
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      initialPeriod = _period(launch?.notificationResponse?.payload);
    }
    available = true;
  }

  Future<void> refreshTimezone() async {
    final name = await NativeBridge.timezone();
    try {
      tz.setLocalLocation(tz.getLocation(name));
    } on ArgumentError {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<ReminderResult> schedule(
    AzkarPeriod period,
    int minutes, {
    bool requestPermissions = false,
  }) async {
    if (!period.supportsReminder) {
      throw ArgumentError('Only morning and evening support daily reminders.');
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (requestPermissions) {
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) return ReminderResult.denied;
    }
    if (await android?.areNotificationsEnabled() == false) {
      return ReminderResult.denied;
    }
    bool exact = await android?.canScheduleExactNotifications() ?? false;
    if (!exact && requestPermissions) {
      exact = await android?.requestExactAlarmsPermission() ?? false;
    }
    await refreshTimezone();
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        minutes ~/ 60,
        minutes % 60,
      );
    }
    Future<void> save(bool precise) => plugin.zonedSchedule(
      period.index + 1,
      period.title,
      period == AzkarPeriod.morning
          ? 'حان وقت أذكار الصباح'
          : 'حان وقت أذكار المساء',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'azkar_daily',
          'تذكير الأذكار',
          channelDescription: 'تذكير يومي بأذكار الصباح والمساء',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: false,
        ),
      ),
      androidScheduleMode: precise
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: period.name,
    );
    try {
      await save(exact);
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      exact = false;
      await save(false);
    }
    return exact ? ReminderResult.exact : ReminderResult.approximate;
  }

  Future<void> cancel(AzkarPeriod p) => plugin.cancel(p.index + 1);
  Future<void> synchronize(AppSettings settings) async {
    if (!available) return;
    for (final p in AzkarPeriod.reminderPeriods) {
      if (settings.enabled(p)) {
        await schedule(p, settings.minutes(p));
      } else {
        await cancel(p);
      }
    }
  }
}
