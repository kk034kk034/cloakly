import 'dart:math' as math;
import 'dart:typed_data';

Uint8List wavHeader({
  required int dataLength,
  int sampleRate = 16000,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final header = ByteData(44);
  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      header.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  header.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  writeString(36, 'data');
  header.setUint32(40, dataLength, Endian.little);
  return header.buffer.asUint8List();
}

Uint8List pcmToWav(Uint8List pcm, {int sampleRate = 16000, int channels = 1}) {
  final header = wavHeader(
    dataLength: pcm.length,
    sampleRate: sampleRate,
    channels: channels,
  );
  final out = BytesBuilder(copy: false)
    ..add(header)
    ..add(pcm);
  return out.takeBytes();
}

double pcmRms(Uint8List pcm) {
  if (pcm.length < 2) return 0;
  var sum = 0.0;
  var count = 0;
  for (var i = 0; i + 1 < pcm.length; i += 2) {
    var sample = pcm[i] | (pcm[i + 1] << 8);
    if (sample >= 32768) sample -= 65536;
    sum += sample * sample;
    count++;
  }
  if (count == 0) return 0;
  return math.sqrt(sum / count) / 32768.0;
}
