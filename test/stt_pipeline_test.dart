import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/audio/pcm_vad.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:cloakly/services/stt/whisper_stt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Uint8List speech(int ms) {
  final bytes = Uint8List(pcmBytesPerSecond * ms ~/ 1000);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < bytes.length; i += 2) {
    data.setInt16(i, 4000, Endian.little);
  }
  return bytes;
}

http.Response transcript(String text) => http.Response(
  jsonEncode({
    'text': text,
    'segments': [
      {'speaker': 'A', 'text': text, 'start': 0.1, 'end': 0.4},
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'short remote utterances flush, queue while busy, and drain on stop',
    () async {
      final firstResponse = Completer<http.Response>();
      final firstStarted = Completer<void>();
      var calls = 0;
      var now = 1000;
      final engine = WhisperStt(
        AppSettings.defaults(),
        lane: SttLane.remote,
        elapsedMs: () => now,
        client: MockClient((request) async {
          calls++;
          if (calls == 1) {
            firstStarted.complete();
            return firstResponse.future;
          }
          return transcript('句子 $calls');
        }),
      );
      final events = <TranscriptEvent>[];
      var closed = false;
      engine.events.listen(events.add, onDone: () => closed = true);
      await engine.start();
      engine.addAudio(speech(500));
      final first = engine.flush();
      await firstStarted.future;
      now = 2000;
      engine.addAudio(speech(500));
      final second = engine.flush();
      now = 3000;
      engine.addAudio(speech(200));
      final stop = engine.stop();
      expect(calls, 1);
      firstResponse.complete(transcript('第一句'));
      await Future.wait([first, second, stop]);
      expect(calls, 3);
      expect(events.map((e) => e.text), ['第一句', '句子 2', '句子 3']);
      expect(events.first.startMs, 600);
      expect(events.first.endMs, 900);
      expect(events[1].startMs, 1600);
      expect(events[2].endMs, 3000);
      expect(events.map((e) => e.speakerLabel).toSet().length, 3);
      expect(events.every((e) => !e.speakerVerified), isTrue);
      expect(closed, isTrue);
      await engine.stop();
    },
  );

  test('failed diarization fallback never invents a known speaker', () async {
    var calls = 0;
    final engine = WhisperStt(
      AppSettings.defaults(),
      lane: SttLane.remote,
      client: MockClient(
        (_) async => ++calls == 1
            ? http.Response('unsupported', 400)
            : transcript('文字仍保留'),
      ),
    );
    final events = <TranscriptEvent>[];
    final errors = <Object>[];
    engine.events.listen(events.add, onError: errors.add);
    await engine.start();
    engine.addAudio(speech(500));
    await engine.stop();
    expect(events.single.text, '文字仍保留');
    expect(events.single.speakerLabel, contains('發言人'));
    expect(events.single.speakerLabel, isNot(contains('對方A')));
    expect(events.single.speakerVerified, isFalse);
    expect(errors, hasLength(1));
  });

  test(
    'authentication failures do not retry as a different model; queue continues',
    () async {
      var calls = 0;
      final engine = WhisperStt(
        AppSettings.defaults(),
        lane: SttLane.self,
        client: MockClient(
          (_) async => ++calls == 1
              ? http.Response('unauthorized', 401)
              : transcript('next'),
        ),
      );
      final events = <TranscriptEvent>[];
      final errors = <Object>[];
      engine.events.listen(events.add, onError: errors.add);
      await engine.start();
      engine.addAudio(speech(500));
      await engine.flush();
      engine.addAudio(speech(500));
      await engine.stop();
      expect(calls, 2);
      expect(errors, hasLength(1));
      expect(events.single.speakerLabel, '我');
    },
  );

  test(
    'silence is not uploaded; continuous speech flushes after four seconds',
    () async {
      var calls = 0;
      final engine = WhisperStt(
        AppSettings.defaults(),
        lane: SttLane.self,
        client: MockClient((_) async {
          calls++;
          return transcript('持續發言');
        }),
      );
      engine.events.listen((_) {});
      await engine.start();
      engine.addAudio(Uint8List(pcmBytesPerSecond * 20));
      await engine.flush();
      expect(calls, 0);
      for (var i = 0; i < 40; i++) {
        engine.addAudio(speech(100));
      }
      await engine.flush();
      expect(calls, 1);
      await engine.stop();
    },
  );

  test('VAD timing follows samples for small and large capture packets', () {
    for (final packetMs in [10, 100, 500]) {
      final vad = PcmVad(silenceMsToEnd: 500, maxUtteranceMs: 4000);
      var ends = 0;
      for (var ms = 0; ms < 1000; ms += packetMs) {
        vad.accept(speech(packetMs), onUtteranceEnd: () => ends++);
      }
      for (var ms = 0; ms < 500; ms += packetMs) {
        vad.accept(
          Uint8List(pcmBytesPerSecond * packetMs ~/ 1000),
          onUtteranceEnd: () => ends++,
        );
      }
      expect(ends, 1, reason: '$packetMs ms packets');
    }
  });
}
