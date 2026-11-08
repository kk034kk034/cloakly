import 'dart:async';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/stt/soniox_stt.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = AppSettings.defaults().copyWith(
    sonioxApiKey: 'local-test-key',
  );

  test('authorization provider cannot hang the startup', () async {
    final stt = SonioxStt(
      settings,
      lane: SttLane.room,
      authorizationTimeout: const Duration(milliseconds: 30),
      apiKeyProvider: () => Completer<String>().future,
    );
    final watch = Stopwatch()..start();
    await expectLater(stt.start(), throwsA(isA<StateError>()));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('websocket connect failure is bounded', () async {
    final stt = SonioxStt(
      settings,
      lane: SttLane.room,
      endpoint: 'ws://127.0.0.1:1',
      connectTimeout: const Duration(milliseconds: 200),
    );
    final watch = Stopwatch()..start();
    await expectLater(stt.start(), throwsA(isA<StateError>()));
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
  });
}
