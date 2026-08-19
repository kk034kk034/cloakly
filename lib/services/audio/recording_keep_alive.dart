import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps microphone capture alive when the phone screen turns off.
class RecordingKeepAlive {
  RecordingKeepAlive._();

  static const _channel = MethodChannel('cloakly/recording_keep_alive');

  static Future<void> start() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('start');
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  static bool get _supported => !kIsWeb && Platform.isAndroid;
}
