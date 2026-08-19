import 'dart:io';

import 'package:cloakly/data/models/models.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RecordingExport {
  static const _channel = MethodChannel('cloakly/files');
  static const recordingsSubdir = '錄音';

  static String fileNameFor(Meeting meeting, [File? file]) {
    final cleaned =
        meeting.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
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

  /// Copies the recording to the project folder when possible. No upload.
  static Future<String> saveToUserFolder({
    required File source,
    required String fileName,
    String? projectFolder,
  }) async {
    if (projectFolder != null && projectFolder.trim().isNotEmpty) {
      try {
        return await saveToProjectFolder(
          source: source,
          projectFolder: projectFolder,
          fileName: fileName,
        );
      } catch (_) {
        // Fall back to Downloads if the project folder is not writable.
      }
    }

    if (Platform.isAndroid) {
      final saved = await _channel.invokeMethod<String>('saveToDownloads', {
        'sourcePath': source.path,
        'fileName': fileName,
        'mimeType': p.extension(source.path).toLowerCase() == '.m4a'
            ? 'audio/mp4'
            : 'audio/wav',
      });
      return saved ?? fileName;
    }

    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return _copyTo(p.join(docs.path, fileName), source);
    }

    final downloads = await getDownloadsDirectory();
    final dir = Directory(
      p.join(
        downloads?.path ?? (await getApplicationDocumentsDirectory()).path,
        'Cloakly',
      ),
    );
    await dir.create(recursive: true);
    return _copyTo(p.join(dir.path, fileName), source);
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
}
