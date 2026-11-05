import 'dart:io';
import 'dart:convert';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      for (final entry in {
        'share_light_png': 'share_light.png',
        'share_dark_png': 'share_dark.png',
      }.entries) {
        final encoded = data?[entry.key];
        if (encoded is String) {
          await File(
            'screenshots/${entry.value}',
          ).writeAsBytes(base64Decode(encoded));
        }
      }
    },
    onScreenshot: (name, bytes, [args]) async {
      final file = File('screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
