import 'dart:io';

import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/audio/aac_encoder.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RecordingExport {
  static const _channel = MethodChannel('cloakly/files');
  static const recordingsSubdir = '錄音';

  static String fileNameFor(Meeting meeting, [File? file]) {
    final cleaned = meeting.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final title = cleaned.isEmpty ? 'cloakly' : cleaned;
    final ext = file == null ? '.m4a' : p.extension(file.path);
    final stamp = DateFormat('yyyyMMdd-HHmm').format(meeting.startedAt);
    return '$stamp $title${ext.isEmpty ? '.m4a' : ext}';
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  static Future<File?> find(Meeting meeting) async {
    final docs = await getApplicationDocumentsDirectory();
    final paths = <String>{
      if (meeting.audioPath != null && meeting.audioPath!.isNotEmpty)
        meeting.audioPath!,
      p.join(docs.path, 'cloakly', '${meeting.id}.m4a'),
      p.join(docs.path, 'cloakly', '${meeting.id}.wav'),
      p.join(docs.path, 'cloakly', 'audio', '${meeting.id}.m4a'),
      p.join(docs.path, 'cloakly', 'audio', '${meeting.id}.wav'),
      p.join(docs.path, 'cloakly', 'audio', '_inbox', '${meeting.id}.m4a'),
      p.join(docs.path, 'cloakly', 'audio', '_inbox', '${meeting.id}.wav'),
      if (meeting.projectId != null && meeting.projectId!.isNotEmpty) ...[
        p.join(
          docs.path,
          'cloakly',
          'audio',
          meeting.projectId!,
          '${meeting.id}.m4a',
        ),
        p.join(
          docs.path,
          'cloakly',
          'audio',
          meeting.projectId!,
          '${meeting.id}.wav',
        ),
      ],
    };
    for (final path in paths) {
      final file = File(path);
      if (await file.exists() && await file.length() > 44) {
        return file;
      }
    }
    return null;
  }

  static Future<File> preferredM4a(File source) async {
    if (p.extension(source.path).toLowerCase() == '.m4a') {
      return source;
    }
    final m4aPath = await AacEncoder.encodeWav(source.path);
    final m4a = File(m4aPath);
    if (m4aPath != source.path &&
        await m4a.exists() &&
        await m4a.length() > 64) {
      return m4a;
    }
    return source;
  }

  /// Copies the recording to the project folder when possible. No upload.
  static Future<String> saveToUserFolder({
    required File source,
    required String fileName,
    String? projectFolder,
  }) async {
    final exportSource = await preferredM4a(source);
    final exportName = _fileNameWithSourceExtension(fileName, exportSource);
    if (projectFolder != null && projectFolder.trim().isNotEmpty) {
      try {
        return await saveToProjectFolder(
          source: exportSource,
          projectFolder: projectFolder,
          fileName: exportName,
        );
      } catch (_) {
        // Fall back to the app documents folder if the project folder is not writable.
      }
    }

    if (Platform.isAndroid) {
      final saved = await _channel.invokeMethod<String>('saveToDownloads', {
        'sourcePath': exportSource.path,
        'fileName': exportName,
        'mimeType': p.extension(exportSource.path).toLowerCase() == '.m4a'
            ? 'audio/mp4'
            : 'audio/wav',
      });
      return saved ?? exportName;
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'cloakly'));
    await dir.create(recursive: true);
    return _copyTo(p.join(dir.path, exportName), exportSource);
  }

  static Future<String> saveToProjectFolder({
    required File source,
    required String projectFolder,
    required String fileName,
  }) async {
    final dir = Directory(p.join(projectFolder, recordingsSubdir));
    await dir.create(recursive: true);
    return _copyTo(p.join(dir.path, fileName), source);
  }

  static Future<String> _copyTo(String destPath, File source) async {
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(dest.path);
    return dest.path;
  }

  static String _fileNameWithSourceExtension(String fileName, File source) {
    final ext = p.extension(source.path);
    if (ext.isEmpty) return fileName;
    return '${p.withoutExtension(fileName)}$ext';
  }
}
