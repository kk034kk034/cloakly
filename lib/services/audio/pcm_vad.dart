import 'dart:typed_data';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/services/audio/wav.dart';

class PcmVad {
  PcmVad({
    this.rmsThreshold = 0.018,
    this.silenceMsToEnd = 700,
    this.maxUtteranceMs = 8000,
  });

  final double rmsThreshold;
  final int silenceMsToEnd;
  final int maxUtteranceMs;

  bool _inSpeech = false;
  int _silenceMs = 0;
  int _speechMs = 0;

  bool accept(Uint8List pcm, {required void Function() onUtteranceEnd}) {
    final durationMs =
        (pcm.length / pcmBytesPerSecond * 1000).round().clamp(20, 250);
    final rms = pcmRms(pcm);
    if (rms >= rmsThreshold) {
      _inSpeech = true;
      _silenceMs = 0;
      _speechMs += durationMs;
      if (_speechMs >= maxUtteranceMs) {
        onUtteranceEnd();
        _speechMs = 0;
      }
      return true;
    }
    if (_inSpeech) {
      _silenceMs += durationMs;
      if (_silenceMs >= silenceMsToEnd) {
        _inSpeech = false;
        _speechMs = 0;
        _silenceMs = 0;
        onUtteranceEnd();
      }
    }
    return false;
  }

  void reset() {
    _inSpeech = false;
    _silenceMs = 0;
    _speechMs = 0;
  }
}
