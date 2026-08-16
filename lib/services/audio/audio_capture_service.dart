import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/services/audio/wav.dart';
import 'package:record/record.dart';

class AudioCaptureService {
  AudioCaptureService();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  RandomAccessFile? _file;
  Future<void> _writeQueue = Future.value();
  int _dataLength = 0;
  bool _inSpeech = false;
  int _silenceMs = 0;
  int _speechMs = 0;
  DateTime? _lastChunkAt;

  bool get isRecording => _sub != null;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start({
    required String wavPath,
    required void Function(Uint8List pcm) onPcm,
    required void Function() onUtteranceEnd,
    double rmsThreshold = 0.018,
  }) async {
    await stop();
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      throw StateError('沒有麥克風權限');
    }

    final file = File(wavPath);
    await file.parent.create(recursive: true);
    _file = await file.open(mode: FileMode.write);
    await _file!.writeFrom(Uint8List(44));
    _dataLength = 0;
    _inSpeech = false;
    _silenceMs = 0;
    _speechMs = 0;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    _sub = stream.listen((pcm) {
      final chunk = Uint8List.fromList(pcm);
      _lastChunkAt = DateTime.now();
      _writeQueue = _writeQueue.then((_) async {
        await _file?.writeFrom(chunk);
      });
      _dataLength += chunk.length;
      onPcm(chunk);

      final durationMs =
          (pcm.length / pcmBytesPerSecond * 1000).round().clamp(20, 250);
      final rms = pcmRms(pcm);
      if (rms >= rmsThreshold) {
        _inSpeech = true;
        _silenceMs = 0;
        _speechMs += durationMs;
        if (_speechMs >= 8000) {
          onUtteranceEnd();
          _speechMs = 0;
        }
      } else if (_inSpeech) {
        _silenceMs += durationMs;
        if (_silenceMs >= 700) {
          _inSpeech = false;
          _speechMs = 0;
          _silenceMs = 0;
          onUtteranceEnd();
        }
      }
    });
  }

  Future<void> pause() async {
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    } else {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    await _writeQueue;
    if (_file != null) {
      final header = wavHeader(dataLength: _dataLength);
      await _file!.setPosition(0);
      await _file!.writeFrom(header);
      await _file!.close();
      _file = null;
    }
  }

  DateTime? get lastChunkAt => _lastChunkAt;
}
