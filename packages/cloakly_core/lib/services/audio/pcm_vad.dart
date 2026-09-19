import 'dart:typed_data';

import 'package:cloakly_core/core/constants.dart';
import 'package:cloakly_core/services/audio/wav.dart';

class PcmVad {
  PcmVad({
    this.rmsThreshold = 0.018,
    this.silenceMsToEnd = 700,
    this.maxUtteranceMs = 4000,
  });

  final double rmsThreshold;
  final int silenceMsToEnd;
  final int maxUtteranceMs;

  bool _inSpeech = false;
  int _silenceBytes = 0;
  int _utteranceBytes = 0;

  bool accept(Uint8List pcm, {required void Function() onUtteranceEnd}) {
    final rms = pcmRms(pcm);
    if (rms >= rmsThreshold) {
      _inSpeech = true;
      _silenceBytes = 0;
    } else if (_inSpeech) {
      _silenceBytes += pcm.length;
    }
    if (_inSpeech) {
      _utteranceBytes += pcm.length;
      if (_silenceBytes * 1000 >= silenceMsToEnd * pcmBytesPerSecond ||
          _utteranceBytes * 1000 >= maxUtteranceMs * pcmBytesPerSecond) {
        reset();
        onUtteranceEnd();
      }
    }
    return rms >= rmsThreshold;
  }

  void reset() {
    _inSpeech = false;
    _silenceBytes = 0;
    _utteranceBytes = 0;
  }
}
