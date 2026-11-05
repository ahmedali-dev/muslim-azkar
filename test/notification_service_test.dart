import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:muslim_azkar/models/zikr.dart';
import 'package:muslim_azkar/models/app_settings.dart';
import 'package:muslim_azkar/services/native_bridge.dart';
import 'package:muslim_azkar/services/notification_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  bool permission = true;
  bool exact = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    permission = true;
    exact = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      NativeBridge.channel,
      (call) async => 'Asia/Riyadh',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {
            'notificationLaunchedApp': true,
            'notificationResponse': {
              'notificationId': 2,
              'notificationResponseType': 0,
              'payload': 'evening',
            },
          };
        case 'areNotificationsEnabled':
        case 'requestNotificationsPermission':
          return permission;
        case 'canScheduleExactNotifications':
        case 'requestExactAlarmsPermission':
          return exact;
        default:
          return null;
      }
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      NativeBridge.channel,
      null,
    );
  });
  test(
    'cold notification opens correct period; exact denial schedules approximate daily alarm',
    () async {
      final service = NotificationService();
      await service.initialize();
      expect(service.initialPeriod, AzkarPeriod.evening);
      expect(
        await service.schedule(
          AzkarPeriod.morning,
          330,
          requestPermissions: true,
        ),
        ReminderResult.approximate,
      );
      final args =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(args['payload'], 'morning');
      expect(args['timeZoneName'], 'Asia/Riyadh');
      expect(
        (args['platformSpecifics'] as Map)['scheduleMode'],
        'inexactAllowWhileIdle',
      );
      expect(args['matchDateTimeComponents'], isNotNull);
      expect(
        calls.any((c) => c.method == 'requestExactAlarmsPermission'),
        true,
      );
    },
  );
  test(
    'notification denial does not schedule or request exact access',
    () async {
      final service = NotificationService();
      await service.initialize();
      permission = false;
      expect(
        await service.schedule(
          AzkarPeriod.evening,
          990,
          requestPermissions: true,
        ),
        ReminderResult.denied,
      );
      expect(calls.any((c) => c.method == 'zonedSchedule'), false);
      expect(
        calls.any((c) => c.method == 'requestExactAlarmsPermission'),
        false,
      );
    },
  );
  test(
    'already granted exact access schedules precisely without permission prompts on resume',
    () async {
      final service = NotificationService();
      await service.initialize();
      exact = true;
      expect(
        await service.schedule(AzkarPeriod.evening, 990),
        ReminderResult.exact,
      );
      final args =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(
        (args['platformSpecifics'] as Map)['scheduleMode'],
        'exactAllowWhileIdle',
      );
      expect(calls.any((c) => c.method.startsWith('request')), false);
    },
  );
  test(
    'additional categories never inherit evening reminder settings',
    () async {
      final settings = AppSettings(eveningEnabled: true);
      expect(settings.enabled(AzkarPeriod.food), false);
      final service = NotificationService();
      await service.initialize();
      await expectLater(
        service.schedule(AzkarPeriod.food, 990),
        throwsArgumentError,
      );
      await service.synchronize(settings);
      expect(calls.where((c) => c.method == 'zonedSchedule').length, 1);
      expect(
        (calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
            as Map)['payload'],
        'evening',
      );
    },
  );
}
