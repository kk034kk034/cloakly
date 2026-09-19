import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloakly_core/core/constants.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/audio/wav.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:http/http.dart' as http;

class WhisperStt implements SttEngine {
  WhisperStt(
    this.settings, {
    required this.lane,
    http.Client? client,
    this.elapsedMs,
  }) : _client = client ?? http.Client();

  final AppSettings settings;
  final SttLane lane;
  final _controller = StreamController<TranscriptEvent>.broadcast();
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final http.Client _client;
  final int Function()? elapsedMs;
  final Stopwatch _clock = Stopwatch();
  Future<void> _pending = Future.value();
  Future<void>? _stopping;
  int? _bufferStartMs;
  int _chunkNumber = 0;
  bool _hasSpeech = false;

  bool get _wantDiarize => lane != SttLane.self;

  @override
  Stream<TranscriptEvent> get events => _controller.stream;

  @override
  Future<void> start() async {
    _clock.start();
  }

  @override
  void addAudio(List<int> pcm) {
    if (_stopping != null || pcm.isEmpty) return;
    _bufferStartMs ??=
        ((elapsedMs?.call() ?? _clock.elapsedMilliseconds) -
                pcm.length * 1000 ~/ pcmBytesPerSecond)
            .clamp(0, 1 << 53);
    _buffer.add(pcm);
    _hasSpeech = _hasSpeech || pcmRms(Uint8List.fromList(pcm)) >= 0.006;
    if (!_hasSpeech && _buffer.length > pcmBytesPerSecond * 0.3) {
      final bytes = _buffer.takeBytes();
      final keep = (pcmBytesPerSecond * 0.3).round();
      _bufferStartMs =
          _bufferStartMs! + (bytes.length - keep) * 1000 ~/ pcmBytesPerSecond;
      _buffer.add(bytes.sublist(bytes.length - keep));
    } else if (_hasSpeech && _buffer.length >= pcmBytesPerSecond * 4) {
      unawaited(flush());
    }
  }

  @override
  Future<void> flush() {
    final pcm = _buffer.takeBytes();
    final startMs = _bufferStartMs ?? 0;
    _bufferStartMs = null;
    final hasSpeech = _hasSpeech;
    _hasSpeech = false;
    if (pcm.isEmpty || !hasSpeech) return _pending;
    final chunk = ++_chunkNumber;
    // Snapshot each utterance even while a previous request is in flight.
    _pending = _pending.then((_) async {
      try {
        await _transcribe(
          pcm,
          diarize: _wantDiarize,
          startMs: startMs,
          chunk: chunk,
        );
      } catch (error, stack) {
        _controller.addError(error, stack);
      }
    });
    return _pending;
  }

  Future<void> _transcribe(
    List<int> pcm, {
    required bool diarize,
    required int startMs,
    required int chunk,
  }) async {
    final wav = pcmToWav(Uint8List.fromList(pcm));
    final uri = Uri.parse('$openaiApiBaseUrl/audio/transcriptions');
    final model = diarize ? openaiDiarizeModel : openaiTranscribeModel;
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${settings.openaiApiKey}'
      ..files.add(
        http.MultipartFile.fromBytes('file', wav, filename: 'chunk.wav'),
      )
      ..fields['model'] = model
      ..fields['response_format'] = diarize ? 'diarized_json' : 'json';
    if (diarize) {
      request.fields['chunking_strategy'] = 'auto';
    }
    if (settings.language == 'zh') {
      request.fields['language'] = 'zh';
    } else if (settings.language == 'en') {
      request.fields['language'] = 'en';
    }

    final response = await (() async {
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    })().timeout(const Duration(seconds: 30));
    final body = response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (diarize &&
          (response.statusCode == 400 || response.statusCode == 422)) {
        _controller.addError(StateError('發言人辨識失敗，本段改用文字辨識，發言人待確認'));
        await _transcribe(pcm, diarize: false, startMs: startMs, chunk: chunk);
        return;
      }
      _controller.addError(StateError('語音辨識失敗：${response.statusCode}'));
      return;
    }

    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      _controller.addError(StateError('語音辨識回傳格式無法解析'));
      return;
    }

    final events = diarize
        ? eventsFromOpenAiDiarizedJson(json, lane: lane)
        : _plainEvents(json);
    for (final event in events) {
      final durationMs = pcm.length * 1000 ~/ pcmBytesPerSecond;
      final localStart = (event.startMs ?? 0).clamp(0, durationMs);
      final localEnd = (event.endMs ?? durationMs).clamp(
        localStart,
        durationMs,
      );
      // A/B are request-local labels, not persistent voice identities.
      _controller.add(
        TranscriptEvent(
          text: event.text,
          isFinal: event.isFinal,
          speakerIndex: lane == SttLane.self ? 0 : event.speakerIndex,
          speakerLabel: lane == SttLane.self
              ? '我'
              : '${diarize ? event.speakerLabel : '發言人'}（片段 $chunk・待確認）',
          speakerVerified: lane == SttLane.self,
          startMs: startMs + localStart,
          endMs: startMs + localEnd,
        ),
      );
    }
  }

  List<TranscriptEvent> _plainEvents(Map<String, dynamic> json) {
    final text = (json['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return const [];
    return [
      TranscriptEvent(
        text: text,
        isFinal: true,
        speakerIndex: SpeakerId.index(lane: lane),
        speakerLabel: SpeakerId.label(lane: lane),
      ),
    ];
  }

  @override
  Future<void> stop() => _stopping ??= _finish();

  Future<void> _finish() async {
    await flush();
    _clock.stop();
    _client.close();
    await _controller.close();
  }
}

List<TranscriptEvent> eventsFromOpenAiDiarizedJson(
  Map<String, dynamic> json, {
  required SttLane lane,
}) {
  final segments = json['segments'] as List<dynamic>?;
  if (segments == null || segments.isEmpty) {
    final text = (json['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return const [];
    return [
      TranscriptEvent(
        text: text,
        isFinal: true,
        speakerIndex: SpeakerId.index(lane: lane),
        speakerLabel: SpeakerId.label(lane: lane),
      ),
    ];
  }

  final events = <TranscriptEvent>[];
  for (final raw in segments) {
    if (raw is! Map) continue;
    final text = (raw['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) continue;
    final diarized = diarizedIndexFromSpeaker(raw['speaker']);
    events.add(
      TranscriptEvent(
        text: text,
        isFinal: true,
        speakerIndex: SpeakerId.index(lane: lane, diarized: diarized),
        speakerLabel: SpeakerId.label(lane: lane, diarized: diarized),
        startMs: raw['start'] is num
            ? ((raw['start'] as num) * 1000).round()
            : null,
        endMs: raw['end'] is num ? ((raw['end'] as num) * 1000).round() : null,
      ),
    );
  }
  return events;
}

int diarizedIndexFromSpeaker(Object? speaker) {
  if (speaker is num) return speaker.toInt();
  if (speaker is! String) return 0;
  final value = speaker.trim();
  if (value.isEmpty) return 0;
  final digits = RegExp(r'\d+').firstMatch(value);
  if (digits != null) return int.parse(digits.group(0)!);
  final letter = RegExp(r'[A-Za-z]').firstMatch(value);
  if (letter != null) {
    return letter.group(0)!.toUpperCase().codeUnitAt(0) - 65;
  }
  return 0;
}
