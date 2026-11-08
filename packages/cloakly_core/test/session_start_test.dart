import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloakly_core/data/db/app_database.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
import 'package:cloakly_core/features/session/session_controller.dart';
import 'package:cloakly_core/services/audio/audio_capture_service.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _Probe {
  final log = <String>[];
  int starts = 0;
  int stops = 0;
  int audioBytes = 0;
  bool failStart = false;
  Duration startDelay = Duration.zero;
  Completer<void>? startGate;
}

class _Audio implements MeetingAudioCapture {
  _Audio(this.probe, {this.allow = true, this.chunk});

  final _Probe probe;
  final bool allow;
  final Uint8List? chunk;

  @override
  Future<bool> hasPermission() async {
    probe.log.add('permission');
    return allow;
  }

  @override
  Future<void> start({
    required String wavPath,
    required void Function(Uint8List pcm) onPcm,
    required void Function() onUtteranceEnd,
  }) async {
    probe.log.add('record');
    if (chunk != null) onPcm(chunk!);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    probe.log.add('record-stop');
  }
}

class _Stt implements SttEngine {
  _Stt(this.probe);

  final _Probe probe;
  final _events = StreamController<TranscriptEvent>.broadcast();

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    probe.starts++;
    probe.log.add('stt');
    final gate = probe.startGate;
    if (gate != null) await gate.future;
    if (probe.startDelay > Duration.zero) {
      await Future<void>.delayed(probe.startDelay);
    }
    if (probe.failStart) throw StateError('stt failed');
  }

  @override
  void addAudio(List<int> pcm) {
    probe.audioBytes += pcm.length;
    probe.log.add('audio');
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> stop() async {
    probe.stops++;
    probe.log.add('stt-stop');
    if (!_events.isClosed) await _events.close();
  }
}

class _Projects extends ProjectsNotifier {
  _Projects(this.contextGate);

  final Completer<void>? contextGate;

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
        personalContext: '背景',
      ),
    ],
  );

  @override
  Future<String> contextBlock({
    String? projectId,
    String? personalContext,
  }) async {
    final gate = contextGate;
    if (gate != null) await gate.future;
    return 'CONTEXT-READY';
  }
}

class _Meetings extends MeetingsNotifier {
  @override
  Future<List<Meeting>> build() async => const [];
}

class _Repo extends MeetingRepository {
  _Repo(super.db, this.root);

  final Directory root;

  @override
  Future<Directory> audioDirFor(String? projectId) async {
    final dir = Directory(p.join(root.path, projectId ?? 'none'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<void> purgeOrphanAudio() async {}
}

class _Ai implements AiService {
  String? projectContext;

  @override
  bool get isConfigured => false;

  @override
  Future<AiTextResult> answerProjectQuestion({
    required String question,
    required String evidence,
  }) => Future.error(UnimplementedError());

  @override
  Future<ProjectPlanResult> generateProjectPlan({required String evidence}) =>
      Future.error(UnimplementedError());

  @override
  Future<MinutesResult> generateMinutes({
    required Meeting meeting,
    required List<TranscriptLine> lines,
    required List<Note> notes,
    String projectContext = '',
  }) async {
    this.projectContext = projectContext;
    return MinutesResult(
      title: meeting.title,
      minutesMarkdown: projectContext,
      relabeled: lines,
    );
  }

  @override
  Future<AiTextResult> suggestAnswer({
    required List<TranscriptLine> recent,
    required String trigger,
    String projectContext = '',
  }) => Future.error(UnimplementedError());
}

Future<ProviderContainer> _container({
  required _Probe probe,
  required _Audio audio,
  Completer<void>? contextGate,
  _Ai? ai,
}) async {
  final database = await AppDatabase.openInMemory();
  final root = Directory(
    '/Users/server/src/cloakly-test-tmp/${DateTime.now().microsecondsSinceEpoch}',
  );
  root.createSync(recursive: true);
  bootSettings = AppSettings.defaults().copyWith(captureSystemAudio: false);
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      meetingRepositoryProvider.overrideWithValue(_Repo(database, root)),
      hostedModeProvider.overrideWithValue(true),
      projectsProvider.overrideWith(() => _Projects(contextGate)),
      meetingsProvider.overrideWith(_Meetings.new),
      meetingAudioCaptureProvider.overrideWithValue(audio),
      sttEngineFactoryProvider.overrideWithValue(
        (settings, {required lane, elapsedMs}) => _Stt(probe),
      ),
      if (ai != null) aiServiceFactoryProvider.overrideWithValue((_) => ai),
      sessionUsageReporterProvider.overrideWithValue(({
        required int durationSeconds,
      }) async {
        probe.log.add('usage:$durationSeconds');
      }),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.db.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  await container.read(projectsProvider.future);
  return container;
}

void main() {
  test('progress is visible before a slow transcription connect', () async {
    final probe = _Probe()..startDelay = const Duration(milliseconds: 250);
    final container = await _container(
      probe: probe,
      audio: _Audio(probe, chunk: Uint8List(8)),
    );
    final notifier = container.read(sessionControllerProvider.notifier);
    final pending = notifier.start(title: '');
    await Future<void>.delayed(Duration.zero);
    final mid = container.read(sessionControllerProvider);
    expect(mid.busyHint, isTrue);
    expect(mid.phase, SessionPhase.idle);
    expect(mid.startupStep, isNot(SessionStartupStep.none));

    await pending;
    final live = container.read(sessionControllerProvider);
    expect(live.phase, SessionPhase.live);
    expect(live.elapsed, Duration.zero);
    expect(probe.log.indexOf('permission'), lessThan(probe.log.indexOf('stt')));
    expect(probe.log.indexOf('record'), lessThan(probe.log.indexOf('stt')));
    expect(probe.audioBytes, 8);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final elapsed = container.read(sessionControllerProvider).elapsed;
    expect(elapsed.inSeconds, 1);
    expect(elapsed.inSeconds, lessThan(2));
  });

  test('permission denial does not open transcription', () async {
    final probe = _Probe();
    final container = await _container(
      probe: probe,
      audio: _Audio(probe, allow: false),
    );
    await container.read(sessionControllerProvider.notifier).start(title: '');
    final state = container.read(sessionControllerProvider);
    expect(probe.starts, 0);
    expect(probe.log, isNot(contains('record')));
    expect(state.phase, SessionPhase.idle);
    expect(state.error, contains('沒有麥克風權限'));
  });

  test('transcription failure stops capture and reports zero usage', () async {
    final probe = _Probe()..failStart = true;
    final container = await _container(probe: probe, audio: _Audio(probe));
    await container.read(sessionControllerProvider.notifier).start(title: '');
    final state = container.read(sessionControllerProvider);
    expect(probe.stops, greaterThan(0));
    expect(probe.log, contains('record-stop'));
    expect(probe.log, contains('usage:0'));
    expect(state.phase, SessionPhase.idle);
    expect(state.error, contains('stt failed'));
  });

  test('cancel during connect leaves idle without an error', () async {
    final probe = _Probe()..startGate = Completer<void>();
    final container = await _container(probe: probe, audio: _Audio(probe));
    final pending = container
        .read(sessionControllerProvider.notifier)
        .start(title: '');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    container.read(sessionControllerProvider.notifier).cancelStart();
    await pending;
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.idle);
    expect(state.error, isNull);
    expect(probe.stops, greaterThan(0));
    expect(probe.log, contains('record-stop'));
  });

  test('a second start while busy does not open another engine', () async {
    final probe = _Probe()..startDelay = const Duration(milliseconds: 150);
    final container = await _container(probe: probe, audio: _Audio(probe));
    final notifier = container.read(sessionControllerProvider.notifier);
    final first = notifier.start(title: '');
    final second = notifier.start(title: '');
    await Future.wait([first, second]);
    expect(probe.starts, 1);
    expect(container.read(sessionControllerProvider).phase, SessionPhase.live);
  });

  test('project context load does not block the live session', () async {
    final probe = _Probe();
    final gate = Completer<void>();
    final ai = _Ai();
    final container = await _container(
      probe: probe,
      audio: _Audio(probe),
      contextGate: gate,
      ai: ai,
    );
    final pending = container
        .read(sessionControllerProvider.notifier)
        .start(title: '');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(sessionControllerProvider).phase, SessionPhase.live);
    expect(gate.isCompleted, isFalse);
    await pending;
    gate.complete();
    await container.read(sessionControllerProvider.notifier).stopAndWrapUp();
    expect(ai.projectContext, 'CONTEXT-READY');
  });
}
