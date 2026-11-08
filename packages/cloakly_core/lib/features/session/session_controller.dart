import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/audio/aac_encoder.dart';
import 'package:cloakly_core/services/audio/audio_capture_service.dart';
import 'package:cloakly_core/services/audio/pcm_vad.dart';
import 'package:cloakly_core/services/audio/pcm_wav_writer.dart';
import 'package:cloakly_core/services/audio/recording_keep_alive.dart';
import 'package:cloakly_core/services/audio/system_audio_capture.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

enum SessionPhase { idle, live, paused, wrappingUp, done }

enum SessionStartupStep { none, preparing, microphone, recording, connecting }

extension SessionStartupStepLabel on SessionStartupStep {
  String get label => switch (this) {
    SessionStartupStep.none => '',
    SessionStartupStep.preparing => '正在準備會議',
    SessionStartupStep.microphone => '正在確認麥克風',
    SessionStartupStep.recording => '正在啟動錄音',
    SessionStartupStep.connecting => '正在連線轉寫',
  };
}

class SessionStartCancelled implements Exception {
  const SessionStartCancelled();
}

class SessionState {
  const SessionState({
    required this.phase,
    required this.meetingId,
    required this.title,
    required this.lines,
    required this.notes,
    required this.suggestions,
    required this.elapsed,
    required this.isDemo,
    required this.partialText,
    required this.error,
    required this.busyHint,
    required this.systemAudioOn,
    this.systemAudioHint,
    this.projectName,
    this.startedAt,
    this.startupStep = SessionStartupStep.none,
  });

  final SessionPhase phase;
  final String meetingId;
  final String title;
  final List<TranscriptLine> lines;
  final List<Note> notes;
  final List<Suggestion> suggestions;
  final Duration elapsed;
  final bool isDemo;
  final String? partialText;
  final String? error;
  final bool busyHint;
  final bool systemAudioOn;
  final String? systemAudioHint;
  final String? projectName;
  final DateTime? startedAt;
  final SessionStartupStep startupStep;

  Suggestion? get latestSuggestion =>
      suggestions.isEmpty ? null : suggestions.last;

  factory SessionState.idle() => const SessionState(
    phase: SessionPhase.idle,
    meetingId: '',
    title: '',
    lines: [],
    notes: [],
    suggestions: [],
    elapsed: Duration.zero,
    isDemo: true,
    partialText: null,
    error: null,
    busyHint: false,
    systemAudioOn: false,
    systemAudioHint: null,
    projectName: null,
    startedAt: null,
    startupStep: SessionStartupStep.none,
  );

  SessionState copyWith({
    SessionPhase? phase,
    String? meetingId,
    String? title,
    List<TranscriptLine>? lines,
    List<Note>? notes,
    List<Suggestion>? suggestions,
    Duration? elapsed,
    bool? isDemo,
    String? partialText,
    String? error,
    bool? busyHint,
    bool? systemAudioOn,
    String? systemAudioHint,
    String? projectName,
    DateTime? startedAt,
    SessionStartupStep? startupStep,
    bool clearError = false,
    bool clearPartial = false,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
      suggestions: suggestions ?? this.suggestions,
      elapsed: elapsed ?? this.elapsed,
      isDemo: isDemo ?? this.isDemo,
      partialText: clearPartial ? null : (partialText ?? this.partialText),
      error: clearError ? null : (error ?? this.error),
      busyHint: busyHint ?? this.busyHint,
      systemAudioOn: systemAudioOn ?? this.systemAudioOn,
      systemAudioHint: systemAudioHint ?? this.systemAudioHint,
      projectName: projectName ?? this.projectName,
      startedAt: startedAt ?? this.startedAt,
      startupStep: startupStep ?? this.startupStep,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  final _uuid = const Uuid();
  late MeetingAudioCapture _audio;
  final _systemAudio = SystemAudioCapture();
  final _systemWav = PcmWavWriter();
  final _systemVad = PcmVad();
  final List<Future<void>> _lineWrites = [];
  bool _disposed = false;

  SttEngine? _micStt;
  SttEngine? _systemStt;
  StreamSubscription<TranscriptEvent>? _micSttSub;
  StreamSubscription<TranscriptEvent>? _systemSttSub;
  StreamSubscription<dynamic>? _systemPcmSub;
  final Map<int, String> _livePartialIds = {};
  Timer? _ticker;
  DateTime? _startedAt;
  String? _audioPath;
  String? _micTempPath;
  String? _systemAudioPath;
  String? _projectId;
  bool _llmBusy = false;
  bool _starting = false;
  String _projectContext = '';
  Future<void>? _projectContextFuture;
  Completer<void>? _cancelStart;
  final List<Uint8List> _pendingPcm = [];
  bool _forwardMicAudio = false;
  DateTime? _captureStartedAt;

  static const _connectBudget = Duration(seconds: 22);

  @override
  SessionState build() {
    _audio = ref.read(meetingAudioCaptureProvider);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_disposeCapture());
    });
    return SessionState.idle();
  }

  void cancelStart() {
    final cancel = _cancelStart;
    if (!_starting || cancel == null || cancel.isCompleted) return;
    cancel.complete();
    ref.read(abandonSessionAuthorizationProvider)?.call();
  }

  Future<void> start({required String title}) async {
    if (_starting ||
        state.phase == SessionPhase.live ||
        state.phase == SessionPhase.wrappingUp) {
      return;
    }
    _starting = true;
    _cancelStart = Completer<void>();
    _pendingPcm.clear();
    _forwardMicAudio = false;
    _captureStartedAt = null;
    state = state.copyWith(
      busyHint: true,
      clearError: true,
      startupStep: SessionStartupStep.preparing,
    );

    final project = ref.read(projectsProvider).valueOrNull?.active;
    final settings = ref
        .read(settingsProvider)
        .copyWith(
          language: 'auto',
          transcriptionTerms:
              (project?.transcriptionTerms.trim().isNotEmpty ?? false)
              ? project!.transcriptionTerms
              : null,
        );
    final isDemo = ref.read(demoModeProvider);
    final hasStt = ref.read(sttAvailableProvider);
    final sttFactory = ref.read(sttEngineFactoryProvider);
    if (!isDemo && !hasStt) {
      state = state.copyWith(
        busyHint: false,
        startupStep: SessionStartupStep.none,
        error: '請先在設定填入 Soniox API 金鑰，才能開始多人串流轉寫。',
      );
      _starting = false;
      _cancelStart = null;
      return;
    }

    String? meetingId;
    try {
      if (!isDemo) {
        state = state.copyWith(startupStep: SessionStartupStep.microphone);
        await _confirmMicrophone();
      }

      final repo = ref.read(meetingRepositoryProvider);
      _projectId = project?.id;
      final background = (project?.personalContext.trim().isNotEmpty ?? false)
          ? project!.personalContext
          : settings.personalContext;
      _beginProjectContext(personalContext: background);
      final id = _uuid.v4();
      meetingId = id;
      final requestedAt = DateTime.now();
      final meeting = Meeting(
        id: id,
        title: title.trim().isEmpty
            ? DateFormat('M月d日 HH:mm 會議').format(requestedAt)
            : title.trim(),
        startedAt: requestedAt,
        status: MeetingStatus.recording,
        projectId: _projectId,
      );
      await repo.upsertMeeting(meeting);
      _throwIfCancelled();

      final audioDir = (await repo.audioDirFor(_projectId)).path;
      _audioPath = p.join(audioDir, '$id.wav');
      _systemAudioPath = p.join(audioDir, '$id-system.tmp.wav');
      _micTempPath = p.join(audioDir, '$id-mic.tmp.wav');
      _livePartialIds.clear();

      if (!isDemo) {
        state = state.copyWith(startupStep: SessionStartupStep.recording);
        await _enableWakelock();
        await RecordingKeepAlive.start();
        _captureStartedAt = DateTime.now();
        await _audio.start(
          wavPath: _micTempPath!,
          onPcm: _onMicPcm,
          onUtteranceEnd: () => unawaited(_micStt?.flush()),
        );
        _throwIfCancelled();
      }

      state = state.copyWith(startupStep: SessionStartupStep.connecting);
      var systemOn = false;
      String? systemHint;
      final wantSystem = settings.captureSystemAudio && !isDemo;
      if (wantSystem) {
        final support = await _systemAudio.probe();
        systemHint = support.hint;
        if (support.supported) {
          try {
            _systemStt = sttFactory(
              settings,
              lane: SttLane.remote,
              elapsedMs: _elapsedSinceCapture,
            );
            _systemSttSub = _systemStt!.events.listen(
              _onTranscript,
              onError: (error) {
                if (_disposed) return;
                state = state.copyWith(error: error.toString());
              },
            );
            await _awaitOrCancel(_systemStt!.start());
            _systemVad.reset();
            await _systemWav.open(_systemAudioPath!);
            _systemPcmSub = _systemAudio.start().listen((pcm) {
              if (state.phase != SessionPhase.live) return;
              _systemWav.add(pcm);
              _systemStt?.addAudio(pcm);
              _systemVad.accept(
                pcm,
                onUtteranceEnd: () => unawaited(_systemStt?.flush()),
              );
            });
            systemOn = true;
          } catch (error) {
            if (error is SessionStartCancelled) rethrow;
            await _systemPcmSub?.cancel();
            _systemPcmSub = null;
            await _systemStt?.stop();
            await _systemSttSub?.cancel();
            _systemStt = null;
            _systemSttSub = null;
            await _systemWav.close();
            systemHint = '系統聲音啟動失敗：$error';
            systemOn = false;
          }
        }
      } else if (!SystemAudioCapture.isDesktop) {
        systemHint = '手機無法擷取會議裡的對方聲音，請用電腦版。';
      }

      _micStt = sttFactory(
        settings,
        lane: systemOn ? SttLane.self : SttLane.room,
        elapsedMs: _elapsedSinceCapture,
      );
      _micSttSub = _micStt!.events.listen(
        _onTranscript,
        onError: (error) {
          if (_disposed) return;
          state = state.copyWith(error: error.toString());
        },
      );
      try {
        await _awaitOrCancel(
          _micStt!.start().timeout(
            _connectBudget,
            onTimeout: () {
              ref.read(abandonSessionAuthorizationProvider)?.call();
              throw TimeoutException('連線轉寫逾時');
            },
          ),
        );
      } on TimeoutException {
        throw StateError('連線轉寫逾時，請再試一次。');
      }
      _flushPendingAudio();

      final liveAt = DateTime.now();
      _startedAt = liveAt;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_startedAt == null || state.phase != SessionPhase.live) return;
        state = state.copyWith(elapsed: DateTime.now().difference(_startedAt!));
      });
      await repo.upsertMeeting(
        Meeting(
          id: id,
          title: meeting.title,
          startedAt: liveAt,
          status: MeetingStatus.recording,
          projectId: _projectId,
        ),
      );

      // Only mark live after STT + mic are actually ready so the UI cannot
      // navigate into a broken session on a second tap.
      state = SessionState(
        phase: SessionPhase.live,
        meetingId: id,
        title: meeting.title,
        lines: const [],
        notes: const [],
        suggestions: const [],
        elapsed: Duration.zero,
        isDemo: isDemo,
        partialText: null,
        error: null,
        busyHint: false,
        systemAudioOn: systemOn,
        systemAudioHint: _speakerHint(
          hasStt: hasStt,
          systemOn: systemOn,
          fallback: systemHint,
        ),
        projectName: project?.name,
        startedAt: liveAt,
        startupStep: SessionStartupStep.none,
      );
    } catch (error) {
      ref.read(abandonSessionAuthorizationProvider)?.call();
      await _disposeCapture();
      final reportUsage = ref.read(sessionUsageReporterProvider);
      if (reportUsage != null) {
        try {
          await reportUsage(
            durationSeconds: 0,
          ).timeout(const Duration(seconds: 8));
        } catch (_) {
          // A known session id is released here. An unknown in-flight
          // reservation is released by clientRequestId, or by the next
          // reserve once the server migration is deployed.
        }
      }
      if (error is SessionStartCancelled) {
        state = SessionState.idle();
      } else {
        state = SessionState.idle().copyWith(
          error: error.toString(),
          busyHint: false,
        );
      }
      if (meetingId != null) {
        // Keep the local meeting row; a failed start may still have audio.
      }
    } finally {
      _starting = false;
      _cancelStart = null;
    }
  }

  void _beginProjectContext({required String personalContext}) {
    _projectContext = '';
    final projectId = _projectId;
    _projectContextFuture = () async {
      try {
        _projectContext = await ref
            .read(projectsProvider.notifier)
            .contextBlock(
              projectId: projectId,
              personalContext: personalContext,
            );
      } catch (_) {
        if (_projectContext.isEmpty) {
          _projectContext = '（專案資料暫時無法讀取）';
        }
      }
    }();
  }

  Future<String> _awaitProjectContext() async {
    final pending = _projectContextFuture;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    return _projectContext;
  }

  Future<void> _confirmMicrophone() async {
    final result = await Future.any<Object?>([
      _audio.hasPermission().then<Object?>((allowed) => allowed),
      if (_cancelStart != null)
        _cancelStart!.future.then<Object?>(
          (_) => const SessionStartCancelled(),
        ),
    ]);
    if (result is SessionStartCancelled) throw result;
    if (result != true) throw StateError('沒有麥克風權限');
  }

  void _throwIfCancelled() {
    if (_cancelStart?.isCompleted ?? false) {
      throw const SessionStartCancelled();
    }
  }

  Future<void> _awaitOrCancel(Future<void> pending) async {
    final cancel = _cancelStart;
    if (cancel == null) {
      await pending;
      return;
    }
    final winner = await Future.any<Object?>([
      pending.then<Object?>((_) => null),
      cancel.future.then<Object?>((_) => const SessionStartCancelled()),
    ]);
    if (winner is SessionStartCancelled) throw winner;
  }

  int _elapsedSinceCapture() {
    final origin = _captureStartedAt ?? _startedAt;
    if (origin == null) return 0;
    return DateTime.now().difference(origin).inMilliseconds;
  }

  void _onMicPcm(Uint8List pcm) {
    if (pcm.isEmpty) return;
    if (_forwardMicAudio) {
      _micStt?.addAudio(pcm);
      return;
    }
    _pendingPcm.add(Uint8List.fromList(pcm));
  }

  void _flushPendingAudio() {
    final pending = List<Uint8List>.of(_pendingPcm);
    _pendingPcm.clear();
    _forwardMicAudio = true;
    final stt = _micStt;
    if (stt == null) return;
    for (final chunk in pending) {
      stt.addAudio(chunk);
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  String? _speakerHint({
    required bool hasStt,
    required bool systemOn,
    String? fallback,
  }) {
    if (hasStt && systemOn) {
      return '串流轉寫：你是「我」，對方在同一連線內持續區分。灰色文字與人物標籤可能更新。';
    }
    if (hasStt && !systemOn) {
      return '${fallback == null || fallback.isEmpty ? '' : '$fallback\n'}串流轉寫：同一支麥克風內持續區分發言人。灰色文字與人物標籤可能更新。';
    }
    return fallback;
  }

  Future<void> pause() async {
    if (state.phase != SessionPhase.live) return;
    await _audio.pause();
    await RecordingKeepAlive.stop();
    state = state.copyWith(phase: SessionPhase.paused);
    await Future.wait([
      if (_micStt != null) _micStt!.flush(),
      if (_systemStt != null) _systemStt!.flush(),
    ]);
    _systemVad.reset();
  }

  Future<void> resume() async {
    if (state.phase != SessionPhase.paused) return;
    await RecordingKeepAlive.start();
    await _audio.resume();
    state = state.copyWith(phase: SessionPhase.live);
  }

  Future<void> addNote(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.meetingId.isEmpty) return;
    final note = Note(
      id: _uuid.v4(),
      meetingId: state.meetingId,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await ref.read(meetingRepositoryProvider).addNote(note);
    state = state.copyWith(notes: [...state.notes, note]);
  }

  Future<void> suggestForLines(Set<String> ids) async {
    if (state.phase != SessionPhase.live &&
        state.phase != SessionPhase.paused) {
      return;
    }
    if (!ref.read(aiServiceProvider).isConfigured && !state.isDemo) {
      state = state.copyWith(error: '逐字稿可繼續使用；回答建議需要 OpenAI API 金鑰。');
      return;
    }
    final selected = state.lines
        .where((line) => ids.contains(line.id) && line.isFinal)
        .toList();
    if (selected.isEmpty) return;
    final first = state.lines.indexWhere(
      (line) => line.id == selected.first.id,
    );
    final last = state.lines.indexWhere((line) => line.id == selected.last.id);
    final contextLines = state.lines
        .sublist(
          first > 6 ? first - 6 : 0,
          last + 4 < state.lines.length ? last + 4 : state.lines.length,
        )
        .where((line) => line.isFinal)
        .toList();
    await _requestSuggestion(
      trigger: selected
          .map((line) => '${line.speaker}：${line.text}')
          .join('\n'),
      contextLines: contextLines,
    );
  }

  Future<String?> stopAndWrapUp() async {
    if (state.meetingId.isEmpty) return null;
    state = state.copyWith(phase: SessionPhase.wrappingUp, busyHint: true);
    await _disposeCapture();

    final reportUsage = ref.read(sessionUsageReporterProvider);
    if (reportUsage != null) {
      try {
        await reportUsage(durationSeconds: state.elapsed.inSeconds);
      } catch (error) {
        state = state.copyWith(error: '同步免費額度失敗，請保持網路連線：$error');
      }
    }

    final repo = ref.read(meetingRepositoryProvider);
    final llm = ref.read(aiServiceProvider);
    final existing = await repo.getById(state.meetingId);
    if (existing == null) return state.meetingId;

    try {
      final projectContext = await _awaitProjectContext();
      final result = await llm.generateMinutes(
        meeting: existing,
        lines: state.lines.where((line) => line.isFinal).toList(),
        notes: state.notes,
        projectContext: projectContext,
      );
      await repo.replaceLines(state.meetingId, result.relabeled);
      final updated = existing.copyWith(
        title: result.title,
        endedAt: DateTime.now(),
        status: MeetingStatus.completed,
        minutesMarkdown: [
          result.minutesMarkdown,
          if (result.usage != null) '\n---\n_AI 用量：${result.usage!.display}_',
        ].join(),
        audioPath: _audioPath,
      );
      await repo.upsertMeeting(updated);
    } catch (error) {
      await repo.upsertMeeting(
        existing.copyWith(
          endedAt: DateTime.now(),
          status: MeetingStatus.completed,
          audioPath: _audioPath,
          minutesMarkdown: '產生會議紀錄失敗：$error',
        ),
      );
    }

    await ref.read(meetingsProvider.notifier).refresh();
    state = state.copyWith(phase: SessionPhase.done, busyHint: false);
    return state.meetingId;
  }

  void _onTranscript(TranscriptEvent event) {
    if (_disposed ||
        (state.phase != SessionPhase.live &&
            state.phase != SessionPhase.paused &&
            state.phase != SessionPhase.wrappingUp)) {
      return;
    }
    final elapsedMs = state.elapsed.inMilliseconds;
    final speaker = event.speakerLabel ?? speakerLabelFor(event.speakerIndex);
    if (event.isRemoved && event.utteranceId != null) {
      state = state.copyWith(
        lines: state.lines
            .where((line) => line.id != event.utteranceId || line.isFinal)
            .toList(),
      );
      return;
    }

    if (!event.isFinal) {
      final id =
          event.utteranceId ??
          _livePartialIds[event.speakerIndex] ??
          _uuid.v4();
      if (event.utteranceId == null) _livePartialIds[event.speakerIndex] = id;
      final line = TranscriptLine(
        id: id,
        meetingId: state.meetingId,
        speaker: speaker,
        speakerIndex: event.speakerIndex,
        text: event.text,
        isFinal: false,
        startMs: event.startMs ?? elapsedMs,
        endMs: event.endMs ?? elapsedMs,
      );
      state = state.copyWith(
        lines: _upsertLine(state.lines, line),
        partialText: event.text,
      );
      return;
    }

    final id =
        event.utteranceId ??
        _livePartialIds.remove(event.speakerIndex) ??
        _uuid.v4();
    final line = TranscriptLine(
      id: id,
      meetingId: state.meetingId,
      speaker: speaker,
      speakerIndex: event.speakerIndex,
      text: event.text,
      isFinal: true,
      startMs: event.startMs ?? elapsedMs,
      endMs: event.endMs ?? elapsedMs,
    );
    state = state.copyWith(
      lines: _upsertLine(state.lines, line),
      clearPartial: true,
    );
    final write = ref.read(meetingRepositoryProvider).upsertLine(line);
    _lineWrites.add(write);
    unawaited(
      write.then<void>(
        (_) {
          _lineWrites.remove(write);
        },
        onError: (Object error) {
          _lineWrites.remove(write);
          if (!_disposed) state = state.copyWith(error: '逐字稿儲存失敗：$error');
        },
      ),
    );
  }

  Future<void> _requestSuggestion({
    required String trigger,
    required List<TranscriptLine> contextLines,
  }) async {
    if (_llmBusy) return;
    if (!ref.read(aiServiceProvider).isConfigured && !state.isDemo) return;
    _llmBusy = true;
    state = state.copyWith(busyHint: true, clearError: true);
    try {
      final llm = ref.read(aiServiceProvider);
      final projectContext = await _awaitProjectContext();
      final result = await llm.suggestAnswer(
        recent: contextLines,
        trigger: trigger,
        projectContext: projectContext,
      );
      final suggestion = Suggestion(
        id: _uuid.v4(),
        meetingId: state.meetingId,
        triggerText: trigger,
        answer: [
          result.content,
          if (result.usage != null) '\n\nAI 用量：${result.usage!.display}',
        ].join(),
        createdAt: DateTime.now(),
      );
      await ref.read(meetingRepositoryProvider).addSuggestion(suggestion);
      state = state.copyWith(
        suggestions: [...state.suggestions, suggestion],
        busyHint: false,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString(), busyHint: false);
    } finally {
      _llmBusy = false;
    }
  }

  List<TranscriptLine> _upsertLine(
    List<TranscriptLine> lines,
    TranscriptLine line,
  ) {
    final index = lines.indexWhere((item) => item.id == line.id);
    if (index == -1) {
      return [...lines, line]..sort((a, b) => a.startMs.compareTo(b.startMs));
    }
    final next = [...lines];
    next[index] = line;
    return next..sort((a, b) => a.startMs.compareTo(b.startMs));
  }

  Future<void> _disposeCapture() async {
    _ticker?.cancel();
    _forwardMicAudio = false;
    _pendingPcm.clear();
    _captureStartedAt = null;
    await _systemPcmSub?.cancel();
    _systemPcmSub = null;
    await _systemWav.close();
    await _systemAudio.stop();
    await _audio.stop();
    await _micStt?.stop();
    await _systemStt?.stop();
    await _micSttSub?.cancel();
    await _systemSttSub?.cancel();
    await Future.wait(_lineWrites.toList());
    _micStt = null;
    _systemStt = null;
    await RecordingKeepAlive.stop();
    final micTemp = _micTempPath;
    final systemTemp = _systemAudioPath;
    final outPath = _audioPath;
    if (micTemp != null && outPath != null) {
      try {
        await mixMonoWavFiles(
          micPath: micTemp,
          systemPath: systemTemp,
          outPath: outPath,
        );
      } catch (_) {
        final leftover = File(micTemp);
        if (await leftover.exists() && micTemp != outPath) {
          await leftover.copy(outPath);
        }
      }
      final mixed = File(outPath);
      if (await mixed.exists()) {
        try {
          final m4aPath = await AacEncoder.encodeWav(outPath);
          if (m4aPath != outPath) {
            await mixed.delete();
            _audioPath = m4aPath;
          }
        } catch (_) {
          // Keep the wav if AAC encoding is unavailable.
        }
      }
      await _deleteScratchAudioFiles(
        micTemp: micTemp,
        systemTemp: systemTemp,
        wavPath: _audioPath == outPath ? null : outPath,
      );
    }
    _micTempPath = null;
    _systemAudioPath = null;
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _deleteScratchAudioFiles({
    required String micTemp,
    String? systemTemp,
    String? wavPath,
  }) async {
    final paths = <String>{micTemp, ?systemTemp, ?wavPath};
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }
}
