import 'dart:async';

import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_mobile/services/hosted_stt_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries one 500 and then returns the temporary key', () async {
    final calls = <String>[];
    var creates = 0;
    final coordinator = HostedSessionCoordinator(
      null,
      deviceId: () async => 'ios:test',
      retryDelay: const Duration(milliseconds: 1),
      invoke: (name, {required body}) async {
        calls.add(name);
        if (name != 'create-meeting-session') {
          return const MeetingFunctionResult(status: 200, data: {'ok': true});
        }
        creates++;
        if (creates == 1) {
          return const MeetingFunctionResult(
            status: 500,
            details: {'error': 'ALLOWANCE_RESERVATION_FAILED'},
          );
        }
        return const MeetingFunctionResult(
          status: 200,
          data: {'sessionId': 'sess-1', 'temporaryApiKey': 'temp-key'},
        );
      },
    );

    expect(await coordinator.temporaryKey(SttLane.room), 'temp-key');
    expect(creates, 2);
    expect(calls.where((name) => name == 'finish-meeting-session'), isEmpty);
  });

  test('timeout does not retry and releases by client request id', () async {
    final bodies = <Map<String, dynamic>>[];
    final gate = Completer<MeetingFunctionResult>();
    final coordinator = HostedSessionCoordinator(
      null,
      deviceId: () async => 'ios:test',
      fetchTimeout: const Duration(milliseconds: 30),
      finishTimeout: const Duration(seconds: 1),
      invoke: (name, {required body}) {
        bodies.add({'name': name, ...body});
        if (name == 'create-meeting-session') return gate.future;
        return Future.value(
          const MeetingFunctionResult(status: 200, data: {'ok': true}),
        );
      },
    );

    final pending = coordinator.temporaryKey(SttLane.room);
    final expectation = expectLater(pending, throwsA(isA<StateError>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    gate.complete(
      const MeetingFunctionResult(
        status: 200,
        data: {'sessionId': 'sess-late', 'temporaryApiKey': 'too-late'},
      ),
    );

    await expectation;
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final creates = bodies.where(
      (body) => body['name'] == 'create-meeting-session',
    );
    expect(creates, hasLength(1));
    final requestId = creates.single['clientRequestId'] as String;
    expect(requestId, isNotEmpty);
    expect(
      bodies.where(
        (body) =>
            body['name'] == 'finish-meeting-session' &&
            (body['clientRequestId'] == requestId ||
                body['sessionId'] == 'sess-late'),
      ),
      isNotEmpty,
    );
  });

  test(
    'missing temporary key still leaves a session that finish can release',
    () async {
      final finished = <String>[];
      final coordinator = HostedSessionCoordinator(
        null,
        deviceId: () async => 'ios:test',
        invoke: (name, {required body}) async {
          if (name == 'finish-meeting-session') {
            finished.add(body['sessionId'] as String);
            return const MeetingFunctionResult(status: 200, data: {'ok': true});
          }
          return const MeetingFunctionResult(
            status: 200,
            data: {'sessionId': 'sess-empty', 'temporaryApiKey': '  '},
          );
        },
      );

      await expectLater(
        coordinator.temporaryKey(SttLane.room),
        throwsA(isA<StateError>()),
      );
      await coordinator.finish(durationSeconds: 0);
      expect(finished, ['sess-empty']);
    },
  );
}
