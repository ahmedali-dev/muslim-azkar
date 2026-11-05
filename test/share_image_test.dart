import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_azkar/data/azkar_repository.dart';
import 'package:muslim_azkar/services/share_image_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Amiri')
      ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    await loader.load();
  });
  test(
    'all Arabic source texts survive pagination in both image formats',
    () async {
      final content = await AzkarRepository.load();
      var multiPage = 0;
      for (final portrait in [true, false]) {
        final style = ShareImageStyle(portrait: portrait);
        for (final items in content.values) {
          for (final zikr in items) {
            final pages = ShareImageRenderer.paginate(zikr.text, style);
            expect(
              pages.join(),
              zikr.text,
              reason: 'No word or diacritic may be dropped',
            );
            expect(pages.every((page) => page.isNotEmpty), isTrue);
            for (final page in pages) {
              final laidOut = TextPainter(
                text: TextSpan(
                  text: page,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 54,
                    height: 1.85,
                  ),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              )..layout(maxWidth: ShareImageRenderer.textWidth);
              expect(
                laidOut.height,
                lessThanOrEqualTo(style.textHeight + .01),
                reason: 'An exported page must not crop the zikr',
              );
              laidOut.dispose();
            }
            if (pages.length > 1) multiPage++;
          }
        }
      }
      expect(multiPage, greaterThan(0));
    },
  );
  test(
    'exports valid PNGs at social image dimensions in both themes',
    () async {
      for (final style in [
        const ShareImageStyle(),
        const ShareImageStyle(dark: true, portrait: false),
      ]) {
        final bytes = await ShareImageRenderer.render(
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',
          category: 'أذكار الصباح',
          repeat: 3,
          style: style,
          page: 1,
          pageCount: 1,
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1080);
        expect(frame.image.height, style.portrait ? 1350 : 1080);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
}
