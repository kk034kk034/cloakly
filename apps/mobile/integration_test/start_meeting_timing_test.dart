import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloakly_core/app.dart';
import 'package:cloakly_core/data/db/app_database.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/audio/audio_capture_service.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Simulated stage delays. These are not production network measurements.
const simulatedContextDelay = Duration(milliseconds: 800);
const simulatedSttDelay = Duration(milliseconds: 1500);
const simulatedPermissionDelay = Duration(milliseconds: 200);

final startupLog = <Map<String, Object?>>[];

int _now() => DateTime.now().millisecondsSinceEpoch;

void _mark(String event, [Map<String, Object?> extra = const {}]) {
  startupLog.add({'event': event, 'ms': _now(), ...extra});
}

class _SlowProjects extends ProjectsNotifier {
  @override
  Future<ProjectLibrary> build() async => ProjectLibrary(
    activeId: 'p1',
    projects: [
      ProjectPack(
        id: 'p1',
        folderPath: '/simulated-project',
        name: 'alpha',
        indexedAt: DateTime(2026),
        docs: const [],
      ),
    ],
  );

  @override
  Future<String> contextBlock({
    String? projectId,
    String? personalContext,
  }) async {
    _mark('context.start');
    await Future<void>.delayed(simulatedContextDelay);
    _mark('context.done');
    return 'simulated-context';
  }
}

class _FakeAudio implements MeetingAudioCapture {
  @override
  Future<bool> hasPermission() async {
    _mark('mic.permission');
    await Future<void>.delayed(simulatedPermissionDelay);
    _mark('mic.permission.done');
    return true;
  }

  @override
  Future<void> start({
    required String wavPath,
    required void Function(Uint8List pcm) onPcm,
    required void Function() onUtteranceEnd,
  }) async {
    _mark('mic.start');
    onPcm(Uint8List(320));
    _mark('mic.chunk');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    _mark('mic.stop');
  }
}

class _TimingStt implements SttEngine {
  final _events = StreamController<TranscriptEvent>.broadcast();

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    _mark('stt.start');
    await Future<void>.delayed(simulatedSttDelay);
    _mark('stt.ready');
  }

  @override
  void addAudio(List<int> pcm) {
    _mark('stt.audio', {'bytes': pcm.length});
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> stop() async {
    _mark('stt.stop');
    if (!_events.isClosed) await _events.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'iOS simulator measures start-meeting feedback with simulated latency',
    (tester) async {
      final database = await AppDatabase.open();
      addTearDown(() async {
        await database.db.close();
      });
      bootSettings = AppSettings.defaults().copyWith(captureSystemAudio: false);

      final router = createAppRouter(initialLocation: '/home');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            hostedModeProvider.overrideWithValue(true),
            projectsProvider.overrideWith(_SlowProjects.new),
            meetingAudioCaptureProvider.overrideWithValue(_FakeAudio()),
            sttEngineFactoryProvider.overrideWithValue(
              (
                AppSettings settings, {
                required SttLane lane,
                int Function()? elapsedMs,
              }) => _TimingStt(),
            ),
            sessionUsageReporterProvider.overrideWithValue(({
              required int durationSeconds,
            }) async {
              _mark('usage.finish', {'seconds': durationSeconds});
            }),
          ],
          child: MaterialApp.router(
            theme: ThemeData.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('開始會議'), findsOneWidget);

      final tapAt = _now();
      _mark('tap');
      await tester.tap(find.text('開始會議'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final progressDuringWait = find
          .byKey(const Key('start-meeting-progress'))
          .evaluate()
          .isNotEmpty;
      final sampleAt = _now();
      _mark('sample.during-wait', {'progressVisible': progressDuringWait});
      int? feedbackAt = progressDuringWait ? sampleAt : null;
      try {
        await binding.takeScreenshot('during_wait');
      } catch (error) {
        _mark('screenshot.during-wait.failed', {'error': error.toString()});
      }

      int? screenAt;
      String? elapsedAtAppear;
      String? elapsedAfterTick;
      final deadline = DateTime.now().add(const Duration(seconds: 12));
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 50));
        final hasProgress = find
            .byKey(const Key('start-meeting-progress'))
            .evaluate()
            .isNotEmpty;
        final onSession = find.byTooltip('暫停').evaluate().isNotEmpty;
        if (hasProgress && feedbackAt == null) {
          feedbackAt = _now();
          _mark('feedback.progress');
          await binding.takeScreenshot('start_progress');
        }
        if (onSession) {
          screenAt = _now();
          _mark('screen.session');
          elapsedAtAppear = _elapsedText(tester);
          await binding.takeScreenshot('start_session');
          break;
        }
      }

      expect(screenAt, isNotNull, reason: 'session screen did not appear');
      await tester.pump(const Duration(milliseconds: 1300));
      elapsedAfterTick = _elapsedText(tester);
      await binding.takeScreenshot('start_timer_tick');

      final stillHomeAt = feedbackAt == null;
      int? eventMs(String name) {
        for (final entry in startupLog) {
          if (entry['event'] == name) return entry['ms'] as int;
        }
        return null;
      }

      final micAt = eventMs('mic.permission');
      final report = <String, Object?>{
        'label': 'simulated-latency',
        'notProductionNetwork': true,
        'audioCapture': 'fake',
        'simulatedContextMs': simulatedContextDelay.inMilliseconds,
        'simulatedSttMs': simulatedSttDelay.inMilliseconds,
        'simulatedPermissionMs': simulatedPermissionDelay.inMilliseconds,
        'progressVisibleDuringWait': progressDuringWait,
        'tapToFeedbackMs': feedbackAt == null ? null : feedbackAt - tapAt,
        'tapToMicMs': micAt == null ? null : micAt - tapAt,
        'tapToScreenMs': screenAt! - tapAt,
        'feedbackIsSessionArrival': stillHomeAt,
        'elapsedAtAppear': elapsedAtAppear,
        'elapsedAfter1300ms': elapsedAfterTick,
        'log': startupLog,
      };
      expect(
        progressDuringWait,
        isTrue,
        reason: 'home should show progress during startup',
      );
      expect(feedbackAt, isNotNull);
      expect(feedbackAt! - tapAt, lessThan(700));
      final events = [for (final entry in startupLog) entry['event'] as String];
      expect(
        events.indexOf('mic.permission'),
        lessThan(events.indexOf('stt.start')),
        reason: 'microphone permission before transcription connect',
      );
      expect(
        events.indexOf('mic.start'),
        lessThan(events.indexOf('stt.ready')),
      );
      expect(events, contains('stt.audio'));
      expect(elapsedAfterTick, '00:01 · alpha');

      debugPrint('STARTUP_TIMING ${jsonEncode(report)}');
    },
  );
}

String? _elapsedText(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .where(
        (value) =>
            value.contains('· alpha') ||
            RegExp(r'^\d{2}:\d{2}').hasMatch(value),
      );
  return texts.isEmpty ? null : texts.first;
}
