import 'dart:io';

import 'package:cloakly/data/models/project_pack.dart';
import 'package:path/path.dart' as p;

class ProjectContextBuilder {
  static const maxTotalChars = 48000;
  static const maxFileChars = 10000;

  Future<String> build(ProjectPack pack) async {
    final buffer = StringBuffer()
      ..writeln('專案：${pack.name}')
      ..writeln('資料夾：${pack.folderPath}')
      ..writeln();

    var used = buffer.length;
    final included = [...pack.includedDocs]
      ..sort((a, b) => b.score.compareTo(a.score));
    for (final doc in included) {
      if (used >= maxTotalChars) break;
      final file = File(p.join(pack.folderPath, doc.relativePath));
      if (!await file.exists()) continue;
      var text = await file.readAsString();
      if (text.trim().isEmpty) continue;
      if (text.length > maxFileChars) {
        text = '${text.substring(0, maxFileChars)}\n…（已截斷）';
      }
      final remaining = maxTotalChars - used;
      if (text.length > remaining) {
        text = '${text.substring(0, remaining)}\n…（已截斷）';
      }
      final block = StringBuffer()
        ..writeln('## ${doc.kind.label} · ${doc.relativePath}')
        ..writeln(text)
        ..writeln();
      buffer.write(block);
      used = buffer.length;
    }
    if (included.isEmpty) {
      buffer.writeln('（尚未勾選任何專案文件）');
    }
    return buffer.toString().trim();
  }
}
