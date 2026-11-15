import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/project/project_document_reader.dart';
import 'package:cloakly_core/services/project/project_indexer.dart';

class ProjectContextBuilder {
  static const maxTotalChars = 48000;
  static const maxFileChars = 10000;

  Future<String> build(ProjectPack pack, {String personalContext = ''}) async {
    final l10n = CloaklyLocale.strings;
    final background = personalContext.trim().isNotEmpty
        ? personalContext.trim()
        : pack.personalContext.trim();
    final buffer = StringBuffer()
      ..writeln(l10n.projectLine(pack.name))
      ..writeln(l10n.folderLine(pack.folderPath));
    if (background.isNotEmpty) {
      buffer.writeln(l10n.roleLine(background));
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
        buffer.writeln(l10n.docUnreadableContent(doc.relativePath));
        used = buffer.length;
        continue;
      }
      if (text.trim().isEmpty) continue;
      if (text.length > maxFileChars) {
        text = '${text.substring(0, maxFileChars)}\n${l10n.truncated}';
      }
      final remaining = maxTotalChars - used;
      if (text.length > remaining) {
        text = '${text.substring(0, remaining)}\n${l10n.truncated}';
      }
      final block = StringBuffer()
        ..writeln('## ${doc.kind.label} · ${doc.relativePath}')
        ..writeln(text)
        ..writeln();
      buffer.write(block);
      used = buffer.length;
    }
    if (included.isEmpty) {
      buffer.writeln(l10n.noSupportedFiles);
    }
    return buffer.toString().trim();
  }
}
