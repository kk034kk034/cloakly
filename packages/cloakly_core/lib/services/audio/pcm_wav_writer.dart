import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloakly_core/services/audio/wav.dart';

class PcmWavWriter {
  RandomAccessFile? _file;
  Future<void> _writeQueue = Future.value();
  int _dataLength = 0;

  Future<void> open(String path) async {
    await close();
    final file = File(path);
    await file.parent.create(recursive: true);
    _file = await file.open(mode: FileMode.write);
    await _file!.writeFrom(Uint8List(44));
    _dataLength = 0;
  }

  void add(Uint8List pcm) {
    final chunk = Uint8List.fromList(pcm);
    _writeQueue = _writeQueue.then((_) async {
      await _file?.writeFrom(chunk);
    });
    _dataLength += chunk.length;
  }

  Future<void> close() async {
    await _writeQueue;
    _writeQueue = Future.value();
    if (_file == null) return;
    final header = wavHeader(dataLength: _dataLength);
    await _file!.setPosition(0);
    await _file!.writeFrom(header);
    await _file!.close();
    _file = null;
  }
}

int _pcm16At(Uint8List bytes, int offset) {
  var sample = bytes[offset] | (bytes[offset + 1] << 8);
  if (sample >= 32768) sample -= 65536;
  return sample;
}

void _writePcm16(Uint8List bytes, int offset, int sample) {
  final clipped = sample.clamp(-32768, 32767);
  final unsigned = clipped < 0 ? clipped + 65536 : clipped;
  bytes[offset] = unsigned & 0xFF;
  bytes[offset + 1] = (unsigned >> 8) & 0xFF;
}

/// Mix two 16-bit mono wavs into [outPath], then delete the inputs.
Future<void> mixMonoWavFiles({
  required String micPath,
  String? systemPath,
  required String outPath,
}) async {
  final mic = File(micPath);
  if (!await mic.exists()) return;

  final remote = systemPath == null ? null : File(systemPath);
  final hasRemote =
      remote != null && await remote.exists() && await remote.length() > 44;

  if (!hasRemote) {
    if (micPath != outPath) {
      await mic.copy(outPath);
      await mic.delete();
    }
    if (remote != null && await remote.exists()) {
      await remote.delete();
    }
    return;
  }

  final micFile = await mic.open();
  final remoteFile = await remote.open();
  final out = File(outPath);
  final outFile = await out.open(mode: FileMode.write);
  try {
    await micFile.setPosition(44);
    await remoteFile.setPosition(44);
    await outFile.writeFrom(Uint8List(44));

    var dataLength = 0;
    const chunkSize = 64 * 1024;
    while (true) {
      final micChunk = await micFile.read(chunkSize);
      final remoteChunk = await remoteFile.read(chunkSize);
      if (micChunk.isEmpty && remoteChunk.isEmpty) break;

      final n = math.max(micChunk.length, remoteChunk.length);
      final even = n - (n % 2);
      if (even <= 0) break;
      final mixed = Uint8List(even);
      for (var i = 0; i + 1 < even; i += 2) {
        final a = i + 1 < micChunk.length ? _pcm16At(micChunk, i) : 0;
        final b = i + 1 < remoteChunk.length ? _pcm16At(remoteChunk, i) : 0;
        _writePcm16(mixed, i, a + b);
      }
      await outFile.writeFrom(mixed);
      dataLength += mixed.length;
    }

    await outFile.setPosition(0);
    await outFile.writeFrom(wavHeader(dataLength: dataLength));
  } finally {
    await micFile.close();
    await remoteFile.close();
    await outFile.close();
  }

  if (micPath != outPath) {
    await mic.delete();
  }
  await remote.delete();
}
