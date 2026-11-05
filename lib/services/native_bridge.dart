import 'package:flutter/services.dart';

class NativeBridge {
  static const channel = MethodChannel('com.muslimazkar/native');
  static Future<String> timezone() async =>
      await channel.invokeMethod<String>('timezone') ?? 'UTC';
  static Future<String> shareDirectory() async =>
      (await channel.invokeMethod<String>('shareDirectory'))!;
  static Future<void> shareImages(List<String> paths) =>
      channel.invokeMethod<void>('shareImages', paths);
  static Future<void> share(String text) =>
      channel.invokeMethod<void>('share', text);
}
