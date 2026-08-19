import 'dart:async';
import 'dart:io';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/audio/aac_encoder.dart';
import 'package:cloakly/services/audio/audio_capture_service.dart';
import 'package:cloakly/services/audio/pcm_vad.dart';
import 'package:cloakly/services/audio/pcm_wav_writer.dart';
import 'package:cloakly/services/audio/recording_keep_alive.dart';
import 'package:cloakly/services/audio/system_audio_capture.dart';
import 'package:cloakly/services/detection/question_detector.dart';
import 'package:cloakly/services/llm/llm_service.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:cloakly/services/stt/stt_factory.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:cloakly/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

enum SessionPhase { idle, live, paused, wrappingUp, done }

class SessionState {
  const SessionState({
    required this.phase,
    required this.meetingId,
    required this.title,
    required this.trigger,
    required this.pace,
    required this.lines,
    required this.notes,
    required this.suggestions,
    required this.elapsed,
    required this.isDemo,
    required this.partialText,
    required this.error,
    required this.busyHint,
    required this.queuedQuestion,
    required this.systemAudioOn,
    this.systemAudioHint,
    this.projectName,
  });

  final SessionPhase phase;
  final String meetingId;
  final String title;
  final AutoTrigger trigger;
  final Pace pace;
  final List<TranscriptLine> lines;
  final List<Note> notes;
  final List<Suggestion> suggestions;
  final Duration elapsed;
  final bool isDemo;
  final String? partialText;
  final String? error;
  final bool busyHint;
  final String? queuedQuestion;
  final bool systemAudioOn;
  final String? systemAudioHint;
  final String? projectName;

  Suggestion? get latestSuggestion =>
      suggestions.isEmpty ? null : suggestions.last;

  factory SessionState.idle() => const SessionState(
        phase: SessionPhase.idle,
        meetingId: '',
        title: '',
        trigger: AutoTrigger.questions,
        pace: Pace.balanced,
        lines: [],
        notes: [],
        suggestions: [],
        elapsed: Duration.zero,
        isDemo: true,
        partialText: null,
        error: null,
        busyHint: false,
        queuedQuestion: null,
        systemAudioOn: false,
        systemAudioHint: null,
        projectName: null,
      );

  SessionState copyWith({
    SessionPhase? phase,
    String? meetingId,
    String? title,
    AutoTrigger? trigger,
    Pace? pace,
    List<TranscriptLine>? lines,
    List<Note>? notes,
    List<Suggestion>? suggestions,
    Duration? elapsed,
    bool? isDemo,
    String? partialText,
    String? error,
    bool? busyHint,
    String? queuedQuestion,
    bool? systemAudioOn,
    String? systemAudioHint,
    String? projectName,
    bool clearError = false,
    bool clearPartial = false,
    bool clearQueued = false,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      trigger: trigger ?? this.trigger,
      pace: pace ?? this.pace,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
      suggestions: suggestions ?? this.suggestions,
      elapsed: elapsed ?? this.elapsed,
      isDemo: isDemo ?? this.isDemo,
      partialText: clearPartial ? null : (partialText ?? this.partialText),
      error: clearError ? null : (error ?? this.error),
      busyHint: busyHint ?? this.busyHint,
      queuedQuestion:
          clearQueued ? null : (queuedQuestion ?? this.queuedQuestion),
      systemAudioOn: systemAudioOn ?? this.systemAudioOn,
      systemAudioHint: systemAudioHint ?? this.systemAudioHint,
      projectName: projectName ?? this.projectName,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  final _uuid = const Uuid();
  final _detector = QuestionDetector();
  final _audio = AudioCaptureService();
  final _systemAudio = SystemAudioCapture();
  final _systemWav = PcmWavWriter();
  final _systemVad = PcmVad(silenceMsToEnd: 1200, maxUtteranceMs: 14000);

  SttEngine? _micStt;
  SttEngine? _systemStt;
  StreamSubscription<TranscriptEvent>? _micSttSub;
  StreamSubscription<TranscriptEvent>? _systemSttSub;
  StreamSubscription<dynamic>? _systemPcmSub;
  final Map<int, String> _livePartialIds = {};
  Timer? _ticker;
  Timer? _pauseTimer;
  DateTime? _startedAt;
  DateTime? _lastSuggestionAt;
  String? _audioPath;
  String? _micTempPath;
  String? _systemAudioPath;
  String? _projectId;
  bool _llmBusy = false;

  @override
  SessionState build() {
    ref.onDispose(() {
      unawaited(_disposeCapture());
    });
    return SessionState.idle();
  }

  Future<void> start({
    required String title,
    required AutoTrigger trigger,
    required Pace pace,
  }) async {
    final settings = ref.read(settingsProvider);
    final repo = ref.read(meetingRepositoryProvider);
    final project = ref.read(projectsProvider).valueOrNull?.active;
    _projectId = project?.id;
    final id = _uuid.v4();
    final now = DateTime.now();
    final meeting = Meeting(
      id: id,
      title: title.trim().isEmpty
          ? DateFormat('M月d日 HH:mm 會議').format(now)
          : title.trim(),
      startedAt: now,
      status: MeetingStatus.recording,
      projectId: _projectId,
    );
    await repo.upsertMeeting(meeting);

    final audioDir = (await repo.audioDirFor(_projectId)).path;
    _audioPath = p.join(audioDir, '$id.wav');
    _systemAudioPath = p.join(audioDir, '$id-system.tmp.wav');
    _micTempPath = p.join(audioDir, '$id-mic.tmp.wav');

    state = SessionState(
      phase: SessionPhase.live,
      meetingId: id,
      title: meeting.title,
      trigger: trigger,
      pace: pace,
      lines: const [],
      notes: const [],
      suggestions: const [],
      elapsed: Duration.zero,
      isDemo: settings.isDemo,
      partialText: null,
      error: null,
      busyHint: false,
      queuedQuestion: null,
      systemAudioOn: false,
      systemAudioHint: null,
      projectName: project?.name,
    );

    _startedAt = now;
    _lastSuggestionAt = null;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt == null || state.phase != SessionPhase.live) return;
      state = state.copyWith(elapsed: DateTime.now().difference(_startedAt!));
    });

    await WakelockPlus.enable();

    var systemOn = false;
    String? systemHint;
    final wantSystem =
        settings.captureSystemAudio && !settings.isDemo;
    if (wantSystem) {
      final support = await _systemAudio.probe();
      systemHint = support.hint;
      if (support.supported) {
        try {
          _systemStt = createSttEngine(
            settings,
            lane: SttLane.remote,
          );
          _systemSttSub = _systemStt!.events.listen(
            _onTranscript,
            onError: (error) {
              state = state.copyWith(error: error.toString());
            },
          );
          await _systemStt!.start();
          _systemVad.reset();
          await _systemWav.open(_systemAudioPath!);
          _systemPcmSub = _systemAudio.start().listen((pcm) {
            _systemWav.add(pcm);
            _systemStt?.addAudio(pcm);
            _systemVad.accept(
              pcm,
              onUtteranceEnd: () => unawaited(_systemStt?.flush()),
            );
          });
          systemOn = true;
        } catch (error) {
          await _systemWav.close();
          systemHint = '系統聲音啟動失敗：$error';
          systemOn = false;
        }
      }
    } else if (!SystemAudioCapture.isDesktop) {
      systemHint = '手機無法擷取會議裡的對方聲音，請用電腦版。';
    }

    _micStt = createSttEngine(
      settings,
      lane: systemOn ? SttLane.self : SttLane.room,
    );
    _micSttSub = _micStt!.events.listen(
      _onTranscript,
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
    await _micStt!.start();

    if (!settings.isDemo) {
      try {
        final allowed = await _audio.hasPermission();
        if (!allowed) {
          throw StateError('沒有麥克風權限');
        }
        await RecordingKeepAlive.start();
        await _audio.start(
          wavPath: _micTempPath!,
          onPcm: (pcm) => _micStt?.addAudio(pcm),
          onUtteranceEnd: () => unawaited(_micStt?.flush()),
        );
      } catch (error) {
        await RecordingKeepAlive.stop();
        state = state.copyWith(error: error.toString());
      }
    }

    state = state.copyWith(
      systemAudioOn: systemOn,
      systemAudioHint: _speakerHint(
        settings: settings,
        systemOn: systemOn,
        fallback: systemHint,
      ),
    );
  }

  String? _speakerHint({
    required AppSettings settings,
    required bool systemOn,
    String? fallback,
  }) {
    if (settings.hasLiveDiarize && systemOn) {
      return '耳機會議：你是「我」。系統聲音會拆成對方A、對方B、對方C。';
    }
    if (settings.hasLiveDiarize && !systemOn) {
      return '現場會議：同一支麥克風會拆成發言人 1、2、3。';
    }
    return fallback;
  }

  Future<void> pause() async {
    if (state.phase != SessionPhase.live) return;
    await _audio.pause();
    await RecordingKeepAlive.stop();
    state = state.copyWith(phase: SessionPhase.paused);
  }

  Future<void> resume() async {
    if (state.phase != SessionPhase.paused) return;
    await RecordingKeepAlive.start();
    await _audio.resume();
    state = state.copyWith(phase: SessionPhase.live);
  }

  void setTrigger(AutoTrigger trigger) {
    state = state.copyWith(trigger: trigger);
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

  Future<void> suggestNow() async {
    final recent = state.lines.where((line) => line.isFinal).toList();
    if (recent.isEmpty) return;
    await _requestSuggestion(
      trigger: recent.length >= 3
          ? recent.sublist(recent.length - 3).map((l) => l.text).join(' ')
          : recent.last.text,
      force: true,
    );
  }

  Future<String?> stopAndWrapUp() async {
    if (state.meetingId.isEmpty) return null;
    state = state.copyWith(phase: SessionPhase.wrappingUp, busyHint: true);
    await _disposeCapture();

    final repo = ref.read(meetingRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final llm = LlmService(settings);
    final existing = await repo.getById(state.meetingId);
    if (existing == null) return state.meetingId;

    try {
      final projectContext =
          await ref
              .read(projectsProvider.notifier)
              .contextBlock(projectId: _projectId);
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
        minutesMarkdown: result.minutesMarkdown,
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
    if (state.phase != SessionPhase.live && state.phase != SessionPhase.paused) {
      return;
    }
    final elapsedMs = state.elapsed.inMilliseconds;
    final speaker = event.speakerLabel ?? speakerLabelFor(event.speakerIndex);

    if (!event.isFinal) {
      final id = _livePartialIds[event.speakerIndex] ?? _uuid.v4();
      _livePartialIds[event.speakerIndex] = id;
      final line = TranscriptLine(
        id: id,
        meetingId: state.meetingId,
        speaker: speaker,
        speakerIndex: event.speakerIndex,
        text: event.text,
        isFinal: false,
        startMs: elapsedMs,
        endMs: elapsedMs,
      );
      state = state.copyWith(
        lines: _upsertLine(state.lines, line),
        partialText: event.text,
      );
      _armPauseTimer();
      return;
    }

    final id = _livePartialIds.remove(event.speakerIndex) ?? _uuid.v4();
    final line = TranscriptLine(
      id: id,
      meetingId: state.meetingId,
      speaker: speaker,
      speakerIndex: event.speakerIndex,
      text: event.text,
      isFinal: true,
      startMs: elapsedMs,
      endMs: elapsedMs,
    );
    state = state.copyWith(
      lines: _upsertLine(state.lines, line),
      clearPartial: true,
    );
    unawaited(ref.read(meetingRepositoryProvider).upsertLine(line));

    if (!_detector.isBackchannel(event.text) &&
        state.trigger == AutoTrigger.questions &&
        _detector.isQuestion(event.text)) {
      state = state.copyWith(queuedQuestion: event.text);
    }
    _armPauseTimer();
  }

  void _armPauseTimer() {
    _pauseTimer?.cancel();
    _pauseTimer = Timer(state.pace.quietWindow, () {
      unawaited(_onQuietWindow());
    });
  }

  Future<void> _onQuietWindow() async {
    if (state.phase != SessionPhase.live) return;
    final queued = state.queuedQuestion;
    if (state.trigger == AutoTrigger.questions && queued != null) {
      await _requestSuggestion(trigger: queued);
      return;
    }
    if (state.trigger == AutoTrigger.pause) {
      final recent = state.lines.where((line) => line.isFinal).toList();
      if (recent.isEmpty) return;
      final last = recent.last.text;
      if (_detector.isBackchannel(last)) return;
      await _requestSuggestion(trigger: last);
    }
  }

  Future<void> _requestSuggestion({
    required String trigger,
    bool force = false,
  }) async {
    if (_llmBusy) return;
    if (!force &&
        _lastSuggestionAt != null &&
        DateTime.now().difference(_lastSuggestionAt!) < state.pace.minGap) {
      return;
    }
    _llmBusy = true;
    state = state.copyWith(busyHint: true, clearQueued: true);
    try {
      final llm = LlmService(ref.read(settingsProvider));
      final recent = state.lines.where((line) => line.isFinal).toList();
      final contextLines =
          recent.length > 12 ? recent.sublist(recent.length - 12) : recent;
      final projectContext =
          await ref
              .read(projectsProvider.notifier)
              .contextBlock(projectId: _projectId);
      final answer = await llm.suggestAnswer(
        recent: contextLines,
        trigger: trigger,
        projectContext: projectContext,
      );
      final suggestion = Suggestion(
        id: _uuid.v4(),
        meetingId: state.meetingId,
        triggerText: trigger,
        answer: answer,
        createdAt: DateTime.now(),
      );
      await ref.read(meetingRepositoryProvider).addSuggestion(suggestion);
      _lastSuggestionAt = DateTime.now();
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
    if (index == -1) return [...lines, line];
    final next = [...lines];
    next[index] = line;
    return next;
  }

  Future<void> _disposeCapture() async {
    _ticker?.cancel();
    _pauseTimer?.cancel();
    await _systemPcmSub?.cancel();
    _systemPcmSub = null;
    await _systemWav.close();
    await _systemAudio.stop();
    await _micSttSub?.cancel();
    await _systemSttSub?.cancel();
    await _micStt?.stop();
    await _systemStt?.stop();
    _micStt = null;
    _systemStt = null;
    await _audio.stop();
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
    await WakelockPlus.disable();
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
