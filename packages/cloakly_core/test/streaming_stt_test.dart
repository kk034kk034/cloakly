import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/stt/soniox_stt.dart';
import 'package:cloakly_core/services/stt/streaming_transcript.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/services/stt/stt_factory.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> token(
  String text,
  String? speaker,
  int start, {
  bool finalText = true,
}) => {
  'text': text,
  'speaker': ?speaker,
  'start_ms': start,
  'end_ms': start + 100,
  'is_final': finalText,
};

void main() {
  test('five speakers retain identity when the first returns later', () {
    final parser = StreamingTranscript(lane: SttLane.room, sessionId: 'room');
    final events = <TranscriptEvent>[];
    for (var i = 1; i <= 5; i++) {
      events.addAll(
        parser.accept({
          'tokens': [token('我是第$i人。', '$i', i * 1000)],
        }),
      );
    }
    events.addAll(
      parser.accept({
        'tokens': [token('我再補充。', '1', 10000)],
      }),
    );
    expect(events.where((e) => e.isFinal).map((e) => e.speakerIndex), [
      0,
      1,
      2,
      3,
      4,
      0,
    ]);
    expect(events.map((e) => e.utteranceId).toSet(), hasLength(6));
  });

  test('speculative text and speaker revisions replace rows, not append', () {
    final parser = StreamingTranscript(
      lane: SttLane.remote,
      sessionId: 'remote',
    );
    final rows = <String, TranscriptEvent>{};
    void apply(Map<String, dynamic> message) {
      for (final e in parser.accept(message)) {
        if (e.isRemoved) {
          rows.remove(e.utteranceId);
        } else {
          rows[e.utteranceId!] = e;
        }
      }
    }

    apply({
      'tokens': [
        token('錯字', '1', 0, finalText: false),
        token('另外一人', '2', 100, finalText: false),
      ],
    });
    expect(rows, hasLength(2));
    apply({
      'tokens': [token('正確內容', '3', 0, finalText: false)],
    });
    expect(rows, hasLength(1));
    apply({
      'tokens': [token('正確內容。', '3', 0)],
    });
    expect(rows, hasLength(1));
    expect(rows.values.single.isFinal, isTrue);
    expect(rows.values.single.text, '正確內容。');
    expect(rows.values.single.speakerLabel, '對方A');
  });

  test('final prefix survives provisional replacement and tail is drained', () {
    final parser = StreamingTranscript(lane: SttLane.room, sessionId: 'room');
    parser.accept({
      'tokens': [token('這個', '1', 0), token('錯誤', '1', 100, finalText: false)],
    });
    final result = parser.accept({
      'tokens': [token('研究', '1', 100)],
      'finished': true,
    });
    expect(result.where((e) => e.isFinal).single.text, '這個研究');
    expect(result.where((e) => e.isFinal).single.startMs, 0);
    expect(result.where((e) => e.isFinal).single.endMs, 200);
  });

  test(
    'unknown speaker stays unknown and whitespace does not fabricate a person',
    () {
      final parser = StreamingTranscript(lane: SttLane.room, sessionId: 'room');
      final result = parser.accept({
        'tokens': [token('不知道誰。', null, 0)],
      });
      expect(result.single.speakerVerified, isFalse);
      expect(result.single.speakerLabel, '發言人待確認');
    },
  );

  test(
    'language is automatic even with legacy restrictions; terms remain supported',
    () {
      final config = sonioxConfiguration(
        AppSettings.defaults().copyWith(
          sonioxApiKey: 'test',
          language: 'zh-en',
          transcriptionTerms: '博士班，Transformer\nTPM',
        ),
        SttLane.room,
      );
      expect(config.containsKey('language_hints'), isFalse);
      expect(config.containsKey('language_hints_strict'), isFalse);
      expect(config['enable_language_identification'], isTrue);
      expect(config['enable_endpoint_detection'], isFalse);
      expect((config['context'] as Map)['terms'], [
        '博士班',
        'Transformer',
        'TPM',
      ]);
      final automatic = sonioxConfiguration(
        AppSettings.defaults().copyWith(language: 'auto'),
        SttLane.self,
      );
      expect(automatic.containsKey('language_hints_strict'), isFalse);
      expect(automatic['enable_speaker_diarization'], isFalse);
    },
  );

  test(
    'live factory never silently substitutes batch or demo with missing STT key',
    () {
      expect(
        () => createSttEngine(
          AppSettings.defaults().copyWith(openaiApiKey: 'test'),
        ),
        throwsStateError,
      );
      final engine = createSttEngine(
        AppSettings.defaults().copyWith(sonioxApiKey: 'test'),
      );
      expect(engine, isA<SonioxStt>());
      expect(
        AppSettings.defaults().copyWith(sonioxApiKey: 'test').isDemo,
        isFalse,
      );
    },
  );

  test(
    'one websocket sends PCM continuously, revises partials, and waits for tail',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var connections = 0;
      var binaryFrames = 0;
      final config = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        connections++;
        final ws = await WebSocketTransformer.upgrade(request);
        ws.listen((message) {
          if (message is String && message.isNotEmpty) {
            final data = jsonDecode(message) as Map<String, dynamic>;
            if (data['api_key'] != null) config.complete(data);
          } else if (message is List<int>) {
            binaryFrames++;
            ws.add(
              jsonEncode({
                'tokens': [token('正在說', '1', 0, finalText: false)],
              }),
            );
          } else if (message == '') {
            ws.add(
              jsonEncode({
                'tokens': [token('完整尾句。', '1', 0)],
                'finished': true,
              }),
            );
            unawaited(ws.close());
          }
        });
      });
      final engine = SonioxStt(
        AppSettings.defaults().copyWith(sonioxApiKey: 'test'),
        lane: SttLane.room,
        endpoint: 'ws://127.0.0.1:${server.port}',
        elapsedMs: () => 1000,
      );
      final events = <TranscriptEvent>[];
      final partial = Completer<void>();
      engine.events.listen((event) {
        events.add(event);
        if (!event.isFinal && !partial.isCompleted) partial.complete();
      });
      await engine.start();
      await config.future;
      engine.addAudio(Uint8List(3200));
      await partial.future.timeout(const Duration(seconds: 2));
      await engine.flush();
      engine.addAudio(Uint8List(3200));
      await engine.stop();
      await engine.stop();
      expect(connections, 1);
      expect(binaryFrames, 2);
      expect(events.where((e) => e.isFinal).single.text, '完整尾句。');
      expect(events.first.utteranceId, events.last.utteranceId);
      expect(events.last.startMs, 900);
    },
  );

  test(
    'capture pause preserves speaker identity and separates meeting timestamps',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var frames = 0;
      server.listen((request) async {
        final ws = await WebSocketTransformer.upgrade(request);
        ws.listen((message) {
          if (message is List<int>) {
            frames++;
            ws.add(
              jsonEncode({
                'tokens': [
                  token(frames == 1 ? '暫停前' : '暫停後。', '1', (frames - 1) * 100),
                ],
              }),
            );
          } else if (message == '') {
            ws.add('{"finished":true,"tokens":[]}');
            unawaited(ws.close());
          }
        });
      });
      var now = 1000;
      final engine = SonioxStt(
        AppSettings.defaults().copyWith(sonioxApiKey: 'test'),
        lane: SttLane.room,
        endpoint: 'ws://127.0.0.1:${server.port}',
        elapsedMs: () => now,
      );
      final events = <TranscriptEvent>[];
      final first = Completer<void>();
      engine.events.listen((event) {
        events.add(event);
        if (!first.isCompleted) first.complete();
      });
      await engine.start();
      engine.addAudio(Uint8List(3200));
      await first.future;
      now = 10100;
      engine.addAudio(Uint8List(3200));
      await engine.stop();
      final finals = events.where((e) => e.isFinal).toList();
      expect(finals.map((e) => e.text), ['暫停前', '暫停後。']);
      expect(finals.first.endMs, 1000);
      expect(finals.last.startMs, 10000);
      expect(finals.map((e) => e.speakerIndex).toSet(), hasLength(1));
    },
  );

  test(
    'missing finished acknowledgement times out without promoting guesses',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final ws = await WebSocketTransformer.upgrade(request);
        ws.listen((_) {});
      });
      final engine = SonioxStt(
        AppSettings.defaults().copyWith(sonioxApiKey: 'test'),
        lane: SttLane.room,
        endpoint: 'ws://127.0.0.1:${server.port}',
        finishTimeout: const Duration(milliseconds: 50),
      );
      final errors = <Object>[];
      final events = <TranscriptEvent>[];
      engine.events.listen(events.add, onError: errors.add);
      await engine.start();
      await engine.stop().timeout(const Duration(seconds: 2));
      expect(errors.single.toString(), contains('逾時'));
      expect(events.where((e) => e.isFinal), isEmpty);
    },
  );

  test('server errors are observable and shutdown does not hang', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((_) {
        ws.add(
          '{"error_code":401,"error_message":"secret must not be logged"}',
        );
      });
    });
    final engine = SonioxStt(
      AppSettings.defaults().copyWith(sonioxApiKey: 'test'),
      lane: SttLane.room,
      endpoint: 'ws://127.0.0.1:${server.port}',
    );
    final error = Completer<Object>();
    engine.events.listen((_) {}, onError: error.complete);
    await engine.start();
    expect((await error.future).toString(), isNot(contains('secret')));
    await engine.stop().timeout(const Duration(seconds: 2));
  });
}
