import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AacEncoder {
  static const _channel = MethodChannel('cloakly/audio_encode');

  static bool get isSupported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;

  static Future<String> encodeWav(String wavPath) async {
    if (!isSupported) {
      return wavPath;
    }
    final outputPath = '${p.withoutExtension(wavPath)}.m4a';
    await _channel.invokeMethod<String>('encodeWavToM4a', {
      'inputPath': wavPath,
      'outputPath': outputPath,
    });
    final out = File(outputPath);
    if (!await out.exists() || await out.length() < 64) {
      throw StateError('m4a 編碼結果是空的');
    }
    return outputPath;
  }
}
