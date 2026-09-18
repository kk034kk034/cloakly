import 'dart:async';
import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/services/audio/pcm_wav_writer.dart';
import 'package:cloakly/services/audio/pcm_vad.dart';
import 'package:record/record.dart';

class AudioCaptureService {
  AudioCaptureService();

  final AudioRecorder _recorder = AudioRecorder();
  final _wav = PcmWavWriter();
  StreamSubscription<Uint8List>? _sub;
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

    await _wav.open(wavPath);
    final vad = PcmVad(rmsThreshold: rmsThreshold);

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        audioInterruption: AudioInterruptionMode.none,
        iosConfig: IosRecordConfig(
          categoryOptions: [
            IosAudioCategoryOption.mixWithOthers,
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
          ],
        ),
      ),
    );

    _sub = stream.listen((pcm) {
      final chunk = Uint8List.fromList(pcm);
      _lastChunkAt = DateTime.now();
      _wav.add(chunk);
      onPcm(chunk);

      vad.accept(chunk, onUtteranceEnd: onUtteranceEnd);
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
    await _wav.close();
  }

  DateTime? get lastChunkAt => _lastChunkAt;
}
