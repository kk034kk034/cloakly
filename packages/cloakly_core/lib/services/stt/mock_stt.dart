import 'dart:async';

import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';

class MockStt implements SttEngine {
  MockStt();

  final _controller = StreamController<TranscriptEvent>.broadcast();
  Timer? _timer;
  var _index = 0;

  static List<({int atMs, int speaker, String text})> get _script {
    final l10n = CloaklyLocale.strings;
    return [
      (atMs: 800, speaker: 1, text: l10n.mockLine1),
      (atMs: 4200, speaker: 0, text: l10n.mockLine2),
      (atMs: 9000, speaker: 1, text: l10n.mockLine3),
      (atMs: 15000, speaker: 0, text: l10n.mockLine4),
      (atMs: 21000, speaker: 1, text: l10n.mockLine5),
      (atMs: 27000, speaker: 2, text: l10n.mockLine6),
      (atMs: 33000, speaker: 1, text: l10n.mockLine7),
    ];
  }

  @override
  Stream<TranscriptEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    final started = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_index >= _script.length) {
        _timer?.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final item = _script[_index];
      if (elapsed >= item.atMs) {
        _controller.add(
          TranscriptEvent(
            text: item.text,
            isFinal: true,
            speakerIndex: item.speaker,
            speakerLabel: SpeakerId.label(
              lane: item.speaker == 0 ? SttLane.self : SttLane.remote,
              diarized: item.speaker == 0 ? 0 : item.speaker - 1,
            ),
          ),
        );
        _index++;
      }
    });
  }

  @override
  void addAudio(List<int> pcm) {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> stop() async {
    _timer?.cancel();
  }
}
