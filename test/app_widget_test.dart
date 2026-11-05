import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_azkar/data/azkar_repository.dart';
import 'package:muslim_azkar/main.dart';
import 'package:muslim_azkar/models/zikr.dart';
import 'package:muslim_azkar/screens/settings_screen.dart';
import 'package:muslim_azkar/providers/app_state.dart';
import 'package:muslim_azkar/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<AzkarPeriod, List<Zikr>> bundledContent;
  setUpAll(() async {
    bundledContent = await AzkarRepository.load();
  });
  testWidgets('small RTL screen reads, counts, advances, and opens settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      await SharedPreferences.getInstance(),
      bundledContent,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          Provider.value(value: NotificationService()),
        ],
        child: const MuslimAzkarApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('طمأنينةٌ لقلبك'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('طمأنينةٌ لقلبك'))),
      TextDirection.rtl,
    );
    await tester.ensureVisible(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 31'), findsOneWidget);
    // Glass surfaces must not reintroduce expensive blur layers.
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.getSize(find.byType(FilledButton).last), const Size(80, 80));
    final themeBeforeTap = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .theme;
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('2 / 31'), findsOneWidget);
    expect(
      identical(
        themeBeforeTap,
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'completion review, restart, and midnight work on a short screen',
    (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 11, 2, 23, 59);
      const first = Zikr(id: 1, text: 'الأول', repeat: 1);
      const last = Zikr(id: 2, text: 'الثاني', repeat: 1);
      final state = AppState(await SharedPreferences.getInstance(), {
        AzkarPeriod.morning: [first, last],
        AzkarPeriod.evening: [first, last],
      }, clock: () => now);
      state.tap(AzkarPeriod.morning, first);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            Provider.value(value: NotificationService()),
          ],
          child: const MuslimAzkarApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('أذكار الصباح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أذكار الصباح'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.ensureVisible(find.byType(FilledButton).last);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text('تقبّل الله منك'), findsOneWidget);
      await tester.ensureVisible(find.text('مراجعة الأذكار'));
      await tester.tap(find.text('مراجعة الأذكار'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      now = DateTime(2026, 11, 3);
      state.ensureToday();
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(state.fraction(AzkarPeriod.morning), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(state.flush);
      state.dispose();
    },
  );
  testWidgets('large accessibility text lays out in dark settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final content = bundledContent;
    final state = AppState(preferences, content);
    state.updateSettings((s) {
      s.themeMode = ThemeMode.dark;
      s.fontLevel = 2;
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          Provider.value(value: NotificationService()),
        ],
        child: const MuslimAzkarApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('كبير'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('جميع الأقسام'));
    await tester.pumpAndSettle();
    expect(find.text('الأقسام: 27'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(state.flush);
    state.dispose();
  });
  testWidgets(
    'library searches Arabic categories and saves independent progress',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        await SharedPreferences.getInstance(),
        bundledContent,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            Provider.value(value: NotificationService()),
          ],
          child: const MuslimAzkarApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('جميع الأقسام'));
      await tester.pumpAndSettle();
      expect(find.text('الأقسام: 27'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('categorySearch')),
        'الطعام',
      );
      await tester.pumpAndSettle();
      expect(find.text('الأقسام: 1'), findsOneWidget);
      await tester.tap(find.text('أذكار الطعام'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 5'), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text('2 / 5'), findsOneWidget);
      expect(state.fraction(AzkarPeriod.food), greaterThan(0));
      expect(state.fraction(AzkarPeriod.morning), 0);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('categorySearch')),
        'فضل الدعاء',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-18')));
      await tester.pumpAndSettle();
      expect(find.text('اضغط بعد إتمام القراءة'), findsOneWidget);
      expect(find.text('تقبّل الله منك'), findsNothing);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text('تقبّل الله منك'), findsOneWidget);
      expect(state.fraction(AzkarPeriod.duaMerit), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(state.flush);
      state.dispose();
    },
  );
}
