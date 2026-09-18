import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/stt/soniox_stt.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final path = Platform.environment['CLOAKLY_TEST_PCM'];
  test(
    'entire supplied recording reaches one local websocket byte for byte',
    () async {
      final source = File(path!);
      final reference = await source.open();
      final sender = await source.open();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final done = Completer<void>();
      var receivedBytes = 0;
      var frames = 0;
      var connections = 0;
      server.listen((request) async {
        connections++;
        final ws = await WebSocketTransformer.upgrade(request);
        try {
          await for (final message in ws) {
            if (message is List<int>) {
              final expected = await reference.read(message.length);
              expect(message, orderedEquals(expected));
              frames++;
              receivedBytes += message.length;
            } else if (message == '') {
              expect(await reference.read(1), isEmpty);
              ws.add(jsonEncode({'finished': true, 'tokens': []}));
              await ws.close();
              done.complete();
              break;
            }
          }
        } catch (error, stack) {
          done.completeError(error, stack);
        }
      });
      final engine = SonioxStt(
        AppSettings.defaults().copyWith(sonioxApiKey: 'local-test-only'),
        lane: SttLane.room,
        endpoint: 'ws://127.0.0.1:${server.port}',
      );
      final errors = <Object>[];
      engine.events.listen((_) {}, onError: errors.add);
      try {
        await engine.start();
        while (true) {
          final bytes = await sender.read(3840);
          if (bytes.isEmpty) break;
          engine.addAudio(bytes);
        }
        await engine.stop();
        await done.future;
        expect(receivedBytes, await source.length());
        expect(connections, 1);
        expect(errors, isEmpty);
        await File('${source.parent.path}/transport_report.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'test': 'local_websocket_full_recording_byte_equality',
            'connections': connections,
            'frames': frames,
            'bytes_received': receivedBytes,
            'byte_for_byte_match': true,
            'cloud_transcription_run': false,
            'note':
                'Transport validation only; no speech recognition or accuracy measurement.',
          }),
        );
      } finally {
        await engine.stop();
        await sender.close();
        await reference.close();
        await server.close(force: true);
      }
    },
    skip: path == null
        ? 'Set CLOAKLY_TEST_PCM to an authorized local PCM recording.'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
