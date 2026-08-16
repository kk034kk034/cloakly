import 'dart:async';

import 'package:cloakly/services/stt/stt_engine.dart';

class MockStt implements SttEngine {
  MockStt();

  final _controller = StreamController<TranscriptEvent>.broadcast();
  Timer? _timer;
  var _index = 0;

  static const _script = <({int atMs, int speaker, String text})>[
    (atMs: 800, speaker: 1, text: '我們開始今天的產品週會，先對一下本週進度。'),
    (atMs: 4200, speaker: 0, text: '好，登入流程這週把錯誤處理補完了，目前內部測試看起來穩定。'),
    (atMs: 9000, speaker: 1, text: '那登入頁的錯誤率有下降嗎？能不能講一下具體數字？'),
    (atMs: 15000, speaker: 0, text: '錯誤率大概從百分之四降到百分之一點五，主要是 token 過期沒導回登入頁。'),
    (atMs: 21000, speaker: 1, text: '下週要上線，你覺得最大的風險是什麼？'),
    (atMs: 27000, speaker: 2, text: '我補一句，客服那邊還在等新的說明文件，不然上線當天一定會被問爆。'),
    (atMs: 33000, speaker: 1, text: '那會議結束前，請各自確認待辦，我們三點後同步文件。'),
  ];

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
