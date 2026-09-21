import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/project/project_document_reader.dart';
import 'package:cloakly_core/services/project/project_indexer.dart';

class ProjectContextBuilder {
  static const maxTotalChars = 48000;
  static const maxFileChars = 10000;

  Future<String> build(ProjectPack pack, {String personalContext = ''}) async {
    final background = personalContext.trim().isNotEmpty
        ? personalContext.trim()
        : pack.personalContext.trim();
    final buffer = StringBuffer()
      ..writeln('專案：${pack.name}')
      ..writeln('資料夾：${pack.folderPath}');
    if (background.isNotEmpty) {
      buffer.writeln('角色與背景：$background');
    }
    buffer.writeln();

    var used = buffer.length;
    final discovered = await ProjectIndexer().index(
      pack.folderPath,
      id: pack.id,
    );
    final included = [...discovered.docs]
      ..sort((a, b) => b.score.compareTo(a.score));
    for (final doc in included) {
      if (used >= maxTotalChars) break;
      String text;
      try {
        final content = await ProjectDocumentReader().read(pack, doc);
        text = [
          for (final section in content.sections)
            '${section.location}\n${section.text}',
          ...content.warnings,
        ].join('\n\n');
      } catch (_) {
        buffer.writeln('（${doc.relativePath} 無法讀取，未提供內容）');
        used = buffer.length;
        continue;
      }
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
      buffer.writeln('（專案資料夾內沒有找到支援的文件）');
    }
    return buffer.toString().trim();
  }
}
