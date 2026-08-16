import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/audio/wav.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:http/http.dart' as http;

class WhisperStt implements SttEngine {
  WhisperStt(
    this.settings, {
    required this.lane,
  });

  final AppSettings settings;
  final SttLane lane;
  final _controller = StreamController<TranscriptEvent>.broadcast();
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  bool _busy = false;
  bool _diarizeBroken = false;

  bool get _wantDiarize => !_diarizeBroken && lane != SttLane.self;

  @override
  Stream<TranscriptEvent> get events => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  void addAudio(List<int> pcm) {
    _buffer.add(pcm);
  }

  @override
  Future<void> flush() async {
    if (_busy) return;
    final pcm = _buffer.takeBytes();
    final minSeconds = _wantDiarize ? 2.5 : 0.6;
    if (pcm.length < pcmBytesPerSecond * minSeconds) {
      if (pcm.isNotEmpty) _buffer.add(pcm);
      return;
    }
    _busy = true;
    try {
      await _transcribe(pcm, diarize: _wantDiarize);
    } catch (error, stack) {
      _controller.addError(error, stack);
    } finally {
      _busy = false;
    }
  }

  Future<void> _transcribe(List<int> pcm, {required bool diarize}) async {
    final wav = pcmToWav(Uint8List.fromList(pcm));
    final uri = Uri.parse('$openaiApiBaseUrl/audio/transcriptions');
    final model = diarize ? openaiDiarizeModel : openaiTranscribeModel;
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${settings.openaiApiKey}'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          wav,
          filename: 'chunk.wav',
        ),
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

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      if (diarize) {
        _diarizeBroken = true;
        await _transcribe(pcm, diarize: false);
        return;
      }
      _controller.addError(StateError('語音辨識失敗：${streamed.statusCode} $body'));
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
      _controller.add(event);
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
  Future<void> stop() async {
    await flush();
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
