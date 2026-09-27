import 'package:flutter/services.dart';

class HostedDeviceId {
  static const _channel = MethodChannel('cloakly/device');
  static Future<String>? _pending;

  static Future<String> current() {
    return _pending ??= _load();
  }

  static Future<String> _load() async {
    final id = (await _channel.invokeMethod<String>('getDeviceId'))?.trim() ?? '';
    final separator = id.indexOf(':');
    final prefix = separator > 0 ? id.substring(0, separator) : '';
    final body = separator >= 0 ? id.substring(separator + 1) : '';
    if ((prefix != 'android' && prefix != 'ios') || body.isEmpty) {
      throw StateError('無法讀取這支手機的識別。');
    }
    return id;
  }
}
