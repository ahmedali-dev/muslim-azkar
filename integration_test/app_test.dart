import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_azkar/providers/app_state.dart';
import 'package:muslim_azkar/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('offline Android launch and counter flow', (tester) async {
    Future<void> capture(String name) async {
      // Let the integration harness fade its touch markers before capture.
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await binding.takeScreenshot(name);
    }

    final prefs = await SharedPreferences.getInstance();
    // Only the dedicated test installation is reset for a repeatable smoke test.
    await prefs.remove('progress');
    await prefs.remove('settings');
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('طمأنينةٌ لقلبك'), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await capture('home');
    await tester.ensureVisible(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 31'), findsOneWidget);
    await capture('morning');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('2 / 31'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);
    await capture('settings');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('جميع الأقسام'));
    await tester.pumpAndSettle();
    expect(find.text('الأقسام: 27'), findsOneWidget);
    await capture('categories');
    await tester.enterText(
      find.byKey(const ValueKey('categorySearch')),
      'الطعام',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-13')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    await capture('food');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final state = tester.element(find.byType(MaterialApp)).read<AppState>();
    state.updateSettings((settings) => settings.themeMode = ThemeMode.dark);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await capture('home_dark');
    await tester.tap(find.byTooltip('جميع الأقسام'));
    await tester.pumpAndSettle();
    await capture('categories_dark');
    await tester.enterText(
      find.byKey(const ValueKey('categorySearch')),
      'المساء',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-2')));
    await tester.pumpAndSettle();
    await capture('evening_dark');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('2 / 30'), findsOneWidget);
    await tester.tap(find.byTooltip('مشاركة كصورة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shareImagePreview')), findsOneWidget);
    await tester.tap(find.text('سكينة'));
    await tester.pumpAndSettle();
    await capture('share_preview_light');
    final lightBytes =
        (tester
                    .widget<Image>(
                      find.byKey(const ValueKey('shareImagePreview')),
                    )
                    .image
                as MemoryImage)
            .bytes;
    await tester.tap(find.text('ليل'));
    await tester.tap(find.text('مربع'));
    await tester.pumpAndSettle();
    await capture('share_preview_dark');
    final darkBytes =
        (tester
                    .widget<Image>(
                      find.byKey(const ValueKey('shareImagePreview')),
                    )
                    .image
                as MemoryImage)
            .bytes;
    binding.reportData = {
      ...?binding.reportData,
      'share_light_png': base64Encode(lightBytes),
      'share_dark_png': base64Encode(darkBytes),
    };
    await tester.tap(find.text('مشاركة جميع الصور'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    });

    expect(find.text('تعذّرت مشاركة الصورة. حاول مرة أخرى.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
