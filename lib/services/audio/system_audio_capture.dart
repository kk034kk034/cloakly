import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemAudioSupport {
  const SystemAudioSupport({required this.supported, required this.hint});

  final bool supported;
  final String hint;
}

class SystemAudioCapture {
  SystemAudioCapture();

  static const _methods = MethodChannel('cloakly/system_audio');
  static const _pcm = EventChannel('cloakly/system_audio/pcm');

  StreamSubscription<dynamic>? _sub;

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<SystemAudioSupport> probe() async {
    if (kIsWeb) {
      return const SystemAudioSupport(supported: false, hint: '瀏覽器無法擷取系統聲音。');
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return const SystemAudioSupport(
        supported: false,
        hint:
            '手機無法穩定擷取 Teams / Meet / Zoom 的對方聲音。請用 Windows / macOS / Linux 電腦版，戴耳機也能聽客戶。',
      );
    }
    try {
      final supported =
          await _methods.invokeMethod<bool>('isSupported') ?? false;
      final hint = await _methods.invokeMethod<String>('platformHint') ?? '';
      return SystemAudioSupport(supported: supported, hint: hint);
    } on MissingPluginException {
      return const SystemAudioSupport(
        supported: false,
        hint: '這個平台還沒接上系統聲音擷取。',
      );
    } catch (error) {
      return SystemAudioSupport(supported: false, hint: '系統聲音無法使用：$error');
    }
  }

  Stream<Uint8List> start() {
    final controller = StreamController<Uint8List>();
    _sub = _pcm.receiveBroadcastStream().listen(
      (event) {
        if (event is Uint8List) {
          controller.add(event);
        } else if (event is List<int>) {
          controller.add(Uint8List.fromList(event));
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () async {
      await _sub?.cancel();
      _sub = null;
    };
    return controller.stream;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
