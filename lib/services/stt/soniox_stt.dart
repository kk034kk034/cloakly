import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'stt_engine.dart';
import 'streaming_transcript.dart';

Map<String, dynamic> sonioxConfiguration(AppSettings settings, SttLane lane) {
  return {
    'api_key': settings.sonioxApiKey,
    'model': 'stt-rt-v5',
    'audio_format': 'pcm_s16le',
    'sample_rate': sampleRate,
    'num_channels': numChannels,
    'enable_speaker_diarization': lane != SttLane.self,
    'enable_language_identification': true,
    // Do not force early finalization: keep context for speaker attribution.
    'enable_endpoint_detection': false,
    'context': {
      'general': [
        {'key': 'domain', 'value': 'Meeting transcription'},
      ],
      'terms': settings.transcriptionTerms
          .split(RegExp(r'[,，\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(100)
          .toList(),
    },
  };
}

class SonioxStt implements SttEngine {
  SonioxStt(
    this.settings, {
    required this.lane,
    this.elapsedMs,
    this.endpoint = 'wss://stt-rt.soniox.com/transcribe-websocket',
    this.finishTimeout = const Duration(seconds: 30),
  }) : _transcript = StreamingTranscript(
         lane: lane,
         sessionId: '${lane.name}:${DateTime.now().microsecondsSinceEpoch}',
       );

  final AppSettings settings;
  final SttLane lane;
  final int Function()? elapsedMs;
  final String endpoint;
  final Duration finishTimeout;
  final StreamingTranscript _transcript;
  final _events = StreamController<TranscriptEvent>.broadcast();
  final _finished = Completer<void>();
  final _clock = Stopwatch();
  final List<({int audioMs, int wallMs})> _anchors = [];
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _keepalive;
  Future<void>? _stopFuture;
  int _audioBytes = 0;
  bool _failed = false;
  bool _receivedFinished = false;

  @override
  Stream<TranscriptEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    if (settings.sonioxApiKey.trim().isEmpty) {
      throw StateError('缺少 Soniox API 金鑰');
    }
    _clock.start();
    try {
      _socket = await WebSocket.connect(
        endpoint,
      ).timeout(const Duration(seconds: 15));
      _subscription = _socket!.listen(
        _receive,
        onError: (Object _) {
          _fail('串流連線中斷；請結束會議並保留錄音供重跑。');
        },
        onDone: () {
          if (!_receivedFinished && !_failed) _fail('串流提前結束，尚未定稿的文字未完成辨識。');
          if (!_finished.isCompleted) _finished.complete();
        },
      );
      _socket!.add(jsonEncode(sonioxConfiguration(settings, lane)));
      _keepalive = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!_failed && _stopFuture == null) {
          _socket?.add('{"type":"keepalive"}');
        }
      });
    } catch (_) {
      _clock.stop();
      throw StateError('無法連線至 Soniox，請檢查網路與設定。');
    }
  }

  void _receive(dynamic raw) {
    try {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      if (message['error_code'] != null) {
        _fail('Soniox 辨識失敗（${message['error_code']}）；請檢查金鑰、額度或音訊設定。');
        return;
      }
      // Map provider audio time to meeting time before sentence grouping so a
      // capture pause is also a boundary, without resetting speaker context.
      final tokens = message['tokens'];
      if (tokens is List) {
        message['tokens'] = tokens.map((token) {
          if (token is! Map<String, dynamic>) return token;
          return {
            ...token,
            if (token['start_ms'] is num)
              'start_ms': _wallTime((token['start_ms'] as num).round()),
            if (token['end_ms'] is num)
              'end_ms': _wallTime(
                (token['end_ms'] as num).round(),
                isEnd: true,
              ),
          };
        }).toList();
      }
      if (message['final_audio_proc_ms'] is num) {
        message['final_audio_proc_ms'] = _wallTime(
          (message['final_audio_proc_ms'] as num).round(),
          isEnd: true,
        );
      }
      for (final event in _transcript.accept(message)) {
        _events.add(
          TranscriptEvent(
            text: event.text,
            isFinal: event.isFinal,
            utteranceId: event.utteranceId,
            isRemoved: event.isRemoved,
            speakerIndex: event.speakerIndex,
            speakerLabel: event.speakerLabel,
            speakerVerified: event.speakerVerified,
            startMs: event.startMs,
            endMs: event.endMs,
          ),
        );
      }
      if (message['finished'] == true) {
        _receivedFinished = true;
        if (!_finished.isCompleted) _finished.complete();
      }
    } catch (_) {
      _fail('無法解析串流辨識結果，原始錄音仍會保留。');
    }
  }

  void _fail(String message) {
    if (_failed || _events.isClosed) return;
    _failed = true;
    _keepalive?.cancel();
    _events.addError(StateError(message));
    if (!_finished.isCompleted) _finished.complete();
    unawaited(_socket?.close());
  }

  int? _wallTime(int? audioMs, {bool isEnd = false}) {
    if (audioMs == null) return null;
    for (final anchor in _anchors.reversed) {
      if (anchor.audioMs < audioMs ||
          (!isEnd && anchor.audioMs == audioMs) ||
          anchor.audioMs == 0) {
        return anchor.wallMs + audioMs - anchor.audioMs;
      }
    }
    return audioMs;
  }

  @override
  void addAudio(List<int> pcm) {
    if (_stopFuture != null || _failed || pcm.isEmpty) return;
    if (_socket == null) throw StateError('串流尚未啟動');
    final audioMs = _audioBytes * 1000 ~/ pcmBytesPerSecond;
    final wallMs =
        ((elapsedMs?.call() ?? _clock.elapsedMilliseconds) -
                pcm.length * 1000 ~/ pcmBytesPerSecond)
            .clamp(0, 1 << 53);
    if (_anchors.isEmpty || (wallMs - _wallTime(audioMs)!).abs() > 250) {
      _anchors.add((audioMs: audioMs, wallMs: wallMs));
    }
    _audioBytes += pcm.length;
    _socket!.add(Uint8List.fromList(pcm));
  }

  /// Capture VAD is not allowed to cut/reset a streaming recognition session.
  @override
  Future<void> flush() async {}

  @override
  Future<void> stop() => _stopFuture ??= _stop();

  Future<void> _stop() async {
    _keepalive?.cancel();
    try {
      if (_socket != null && !_failed && !_receivedFinished) {
        _socket!.add('');
        await _finished.future.timeout(finishTimeout);
      }
    } on TimeoutException {
      _fail('等待串流尾句逾時；未完成的文字保留為暫定，請用原始錄音重跑。');
    } finally {
      await _subscription?.cancel();
      await _socket?.close();
      _clock.stop();
      await _events.close();
    }
  }
}
