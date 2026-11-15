import 'dart:async';
import 'dart:io';

import 'package:cloakly_core/l10n/cloakly_locale.dart';
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
    final l10n = CloaklyLocale.strings;
    if (kIsWeb) {
      return SystemAudioSupport(
        supported: false,
        hint: l10n.browserNoSystemAudio,
      );
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return SystemAudioSupport(supported: false, hint: l10n.mobileNoCallAudio);
    }
    try {
      final supported =
          await _methods.invokeMethod<bool>('isSupported') ?? false;
      final hint = await _methods.invokeMethod<String>('platformHint') ?? '';
      return SystemAudioSupport(supported: supported, hint: hint);
    } on MissingPluginException {
      return SystemAudioSupport(
        supported: false,
        hint: l10n.systemAudioNotWired,
      );
    } catch (error) {
      return SystemAudioSupport(
        supported: false,
        hint: l10n.systemAudioUnavailable('$error'),
      );
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
