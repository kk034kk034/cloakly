import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/app_localizations_en.dart';
import 'package:cloakly_core/l10n/app_localizations_zh.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:pdfrx/pdfrx.dart';

/// Locale lookup that does not construct a [Locale]. Safe inside [Isolate.run],
/// which cannot use dart:ui.
AppLocalizations _stringsForIsolate(String languageCode, String? scriptCode) {
  if (languageCode == 'zh') {
    if (scriptCode == 'Hant') return AppLocalizationsZhHant();
    return AppLocalizationsZh();
  }
  return AppLocalizationsEn();
}

class DocumentSection {
  const DocumentSection(this.location, this.text);
  final String location;
  final String text;
}

class ProjectDocument {
  const ProjectDocument(this.sections, this.modified, this.warnings);
  final List<DocumentSection> sections;
  final DateTime modified;
  final List<String> warnings;
}

/// Extracts selectable slide/table text and speaker notes, never executes Office
/// content or extracts ZIP entries to disk. Images and charts require vision/OCR.
class ProjectDocumentReader {
  static const textExtensions = {
    '.md',
    '.txt',
    '.json',
    '.yaml',
    '.yml',
    '.csv',
    '.rst',
    '.adoc',
    '.xml',
  };
  static const codeExtensions = {
    '.dart',
    '.py',
    '.js',
    '.jsx',
    '.ts',
    '.tsx',
    '.java',
    '.kt',
    '.kts',
    '.swift',
    '.m',
    '.mm',
    '.c',
    '.h',
    '.cpp',
    '.hpp',
    '.cs',
    '.go',
    '.rs',
    '.rb',
    '.php',
    '.vue',
    '.svelte',
    '.html',
    '.css',
    '.scss',
    '.sql',
    '.sh',
    '.ps1',
    '.bat',
    '.toml',
    '.ini',
    '.cfg',
    '.gradle',
    '.cmake',
    '.r',
    '.ipynb',
    '.proto',
    '.graphql',
  };
  static const officeExtensions = {'.pptx', '.docx', '.xlsx', '.pdf'};
  static const extensions = {
    ...textExtensions,
    ...codeExtensions,
    ...officeExtensions,
  };
  static bool supports(String path) =>
      extensions.contains(p.extension(path).toLowerCase()) ||
      {
        'dockerfile',
        'makefile',
        'cmakelists.txt',
        'license',
      }.contains(p.basename(path).toLowerCase());
  static const maxTextBytes = 256 * 1024;
  static const maxPptxBytes = 50 * 1024 * 1024;

  static int maxBytes(String path) =>
      officeExtensions.contains(p.extension(path).toLowerCase())
      ? maxPptxBytes
      : maxTextBytes;

  Future<ProjectDocument> read(ProjectPack pack, KnowledgeDoc doc) async {
    final root = await Directory(pack.folderPath).resolveSymbolicLinks();
    final candidate = p.normalize(p.join(root, doc.relativePath));
    final l10n = CloaklyLocale.strings;
    if (!p.isWithin(root, candidate)) {
      throw FormatException(l10n.docOutsideProject);
    }
    final resolved = await File(candidate).resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw FormatException(l10n.linkOutsideProject);
    }
    return readFile(resolved);
  }

  Future<ProjectDocument> readFile(String path) {
    if (p.extension(path).toLowerCase() == '.pdf') return _pdf(path);
    final locale = CloaklyLocale.current;
    final languageCode = locale.languageCode;
    final scriptCode = locale.scriptCode;
    return Isolate.run(() {
      final l10n = _stringsForIsolate(languageCode, scriptCode);
      final ext = p.extension(path).toLowerCase();
      if (!supports(path)) {
        throw FormatException(l10n.unsupportedOffice);
      }
      final file = File(path);
      final stat = file.statSync();
      if (stat.size > maxBytes(path)) {
        throw FormatException(
          officeExtensions.contains(ext)
              ? l10n.officeTooLarge
              : l10n.textTooLarge,
        );
      }
      if (!officeExtensions.contains(ext)) {
        return ProjectDocument(
          [DocumentSection(l10n.documentSection, file.readAsStringSync())],
          stat.modified,
          const [],
        );
      }
      try {
        return ext == '.pptx'
            ? _presentation(file.readAsBytesSync(), stat.modified, l10n)
            : _office(file.readAsBytesSync(), stat.modified, ext, l10n);
      } on FormatException {
        rethrow;
      } catch (_) {
        throw FormatException(l10n.officeUnreadable);
      }
    });
  }

  static Future<ProjectDocument> _pdf(String path) async {
    final l10n = CloaklyLocale.strings;
    final stat = await File(path).stat();
    if (stat.size > maxPptxBytes) throw FormatException(l10n.pdfTooLarge);
    await pdfrxFlutterInitialize();
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(path);
      if (document.pages.length > 500) {
        throw FormatException(l10n.pdfTooManyPages);
      }
      final sections = <DocumentSection>[];
      final warnings = <String>[l10n.pdfTextLayerWarning];
      var total = 0;
      for (final page in document.pages) {
        final text = (await page.loadText())?.fullText.trim() ?? '';
        total += text.length;
        if (total > 2000000) throw FormatException(l10n.pdfTooMuchText);
        if (text.isEmpty) {
          warnings.add(l10n.pdfPageNoText(page.pageNumber));
        } else {
          sections.add(DocumentSection(l10n.pdfPage(page.pageNumber), text));
        }
      }
      return ProjectDocument(sections, stat.modified, warnings);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException(l10n.pdfUnreadable);
    } finally {
      await document?.dispose();
    }
  }

  static ProjectDocument _office(
    List<int> bytes,
    DateTime modified,
    String ext,
    AppLocalizations l10n,
  ) {
    final archive = ZipDecoder().decodeBytes(bytes);
    var total = 0;
    XmlDocument? xml(String name) {
      final entry = archive.findFile(name);
      if (entry == null) return null;
      total += entry.size;
      if (entry.size > 8 * 1024 * 1024 || total > 24 * 1024 * 1024) {
        throw FormatException(l10n.xmlTooLarge);
      }
      final content = entry.readBytes();
      if (content == null) throw FormatException(l10n.contentUndecompressible);
      return XmlDocument.parse(utf8.decode(content));
    }

    Iterable<XmlElement> elements(XmlNode node, String local) => node
        .descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == local);
    final sections = <DocumentSection>[];
    if (ext == '.docx') {
      final body = xml('word/document.xml');
      if (body == null) throw FormatException(l10n.notDocx);
      var i = 0;
      for (final paragraph in elements(body, 'p')) {
        final value = elements(
          paragraph,
          't',
        ).map((e) => e.innerText).join().trim();
        if (value.isNotEmpty) {
          sections.add(DocumentSection(l10n.wordParagraph(++i), value));
        }
      }
      return ProjectDocument(sections, modified, [l10n.wordWarning]);
    }
    final workbook = xml('xl/workbook.xml');
    final rels = xml('xl/_rels/workbook.xml.rels');
    if (workbook == null || rels == null) {
      throw FormatException(l10n.notXlsx);
    }
    final strings = xml('xl/sharedStrings.xml');
    final shared = [
      if (strings != null)
        for (final si in elements(strings, 'si'))
          elements(si, 't').map((e) => e.innerText).join(),
    ];
    final paths = {
      for (final rel in elements(rels, 'Relationship'))
        if (rel.getAttribute('TargetMode') != 'External')
          rel.getAttribute('Id'): rel.getAttribute('Target'),
    };
    for (final sheet in elements(workbook, 'sheet')) {
      final ref = sheet.attributes
          .where((a) => a.name.local == 'id' && a.name.prefix != null)
          .firstOrNull
          ?.value;
      final target = paths[ref];
      final part = target == null
          ? null
          : xml(
              p.posix
                  .normalize(p.posix.join('xl', target))
                  .replaceFirst(RegExp(r'^/'), ''),
            );
      if (part == null) throw FormatException(l10n.sheetMissing);
      final sheetName = sheet.getAttribute('name') ?? l10n.sheetDefault;
      String? firstRow;
      for (final row in elements(part, 'row')) {
        final cells = <String>[];
        for (final cell in row.childElements.where(
          (e) => e.name.local == 'c',
        )) {
          final raw = elements(cell, 'v').firstOrNull?.innerText ?? '';
          final type = cell.getAttribute('t');
          final index = int.tryParse(raw);
          final value = type == 's'
              ? (index != null && index >= 0 && index < shared.length
                    ? shared[index]
                    : '')
              : type == 'inlineStr'
              ? elements(cell, 't').map((e) => e.innerText).join()
              : type == 'b'
              ? (raw == '1' ? 'TRUE' : 'FALSE')
              : raw;
          final formula = elements(cell, 'f').firstOrNull?.innerText;
          if (value.isNotEmpty || formula != null) {
            final cellRef = cell.getAttribute('r') ?? '';
            cells.add(
              formula == null
                  ? '$cellRef: $value'
                  : l10n.cachedFormula(cellRef, value, formula),
            );
          }
        }
        if (cells.isNotEmpty) {
          final values = cells.join(' | ');
          sections.add(
            DocumentSection(
              l10n.sheetRow(sheetName, row.getAttribute('r') ?? '?'),
              firstRow == null ? values : l10n.headerRowNote(firstRow, values),
            ),
          );
          firstRow ??= values;
        }
      }
    }
    return ProjectDocument(sections, modified, [l10n.excelWarning]);
  }

  static ProjectDocument _presentation(
    List<int> bytes,
    DateTime modified,
    AppLocalizations l10n,
  ) {
    final archive = ZipDecoder().decodeBytes(bytes);
    var xmlBytes = 0;
    XmlDocument? xml(String path) {
      final entry = archive.findFile(path);
      if (entry == null) return null;
      xmlBytes += entry.size;
      if (entry.size > 2 * 1024 * 1024 || xmlBytes > 16 * 1024 * 1024) {
        throw FormatException(l10n.pptxXmlTooLarge);
      }
      final content = entry.readBytes();
      if (content == null) throw FormatException(l10n.pptxUndecompressible);
      return XmlDocument.parse(utf8.decode(content));
    }

    Iterable<XmlElement> elements(XmlNode node, String local) => node
        .descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == local);
    Map<String, String> relationships(String part, String type) {
      final relPath = p.posix.join(
        p.posix.dirname(part),
        '_rels',
        '${p.posix.basename(part)}.rels',
      );
      final rels = xml(relPath);
      return {
        if (rels != null)
          for (final rel in elements(rels, 'Relationship'))
            if (rel.getAttribute('TargetMode') != 'External' &&
                (rel.getAttribute('Type') ?? '').endsWith('/$type'))
              rel.getAttribute('Id') ?? '': p.posix
                  .normalize(
                    p.posix.join(
                      p.posix.dirname(part),
                      rel.getAttribute('Target') ?? '',
                    ),
                  )
                  .replaceFirst(RegExp(r'^/'), ''),
      };
    }

    String text(XmlDocument document, {bool notes = false}) {
      final blocks = <String>[];
      for (final paragraph in elements(document, 'p')) {
        if (notes) {
          final shapes = paragraph.ancestors.whereType<XmlElement>().where(
            (e) => e.name.local == 'sp',
          );
          if (shapes.any(
            (shape) => elements(shape, 'ph').any(
              (ph) => {
                'sldImg',
                'sldNum',
                'hdr',
                'ftr',
                'dt',
              }.contains(ph.getAttribute('type')),
            ),
          )) {
            continue;
          }
        }
        final value = elements(
          paragraph,
          't',
        ).map((e) => e.innerText).join().trim();
        if (value.isNotEmpty) blocks.add(value);
      }
      return blocks.join('\n');
    }

    final presentation = xml('ppt/presentation.xml');
    if (presentation == null) throw FormatException(l10n.notPptx);
    final slides = relationships('ppt/presentation.xml', 'slide');
    final ids = elements(presentation, 'sldId').toList();
    if (ids.length > 300) throw FormatException(l10n.pptxTooManySlides);
    final sections = <DocumentSection>[];
    final warnings = <String>[l10n.pptxWarning];
    for (var i = 0; i < ids.length; i++) {
      final ref = ids[i].attributes
          .where((a) => a.name.local == 'id' && a.name.prefix != null)
          .firstOrNull
          ?.value;
      final path = slides[ref];
      final slide = path == null ? null : xml(path);
      if (slide == null) throw FormatException(l10n.slideMissing(i + 1));
      final body = text(slide);
      if (body.isNotEmpty) {
        sections.add(DocumentSection(l10n.slidePage(i + 1), body));
      }
      var notesText = '';
      for (final notePath in relationships(path!, 'notesSlide').values) {
        final notes = xml(notePath);
        if (notes != null) notesText += '${text(notes, notes: true)}\n';
      }
      if (notesText.trim().isNotEmpty) {
        sections.add(DocumentSection(l10n.slideNotes(i + 1), notesText.trim()));
      }
      if (body.isEmpty && notesText.trim().isEmpty) {
        warnings.add(l10n.slideNoText(i + 1));
      }
    }
    return ProjectDocument(sections, modified, warnings);
  }
}
