import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import 'package:pdfrx/pdfrx.dart';

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
    if (!p.isWithin(root, candidate)) throw const FormatException('文件不在專案資料夾內');
    final resolved = await File(candidate).resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) throw const FormatException('文件連結超出專案資料夾');
    return readFile(resolved);
  }

  Future<ProjectDocument> readFile(String path) {
    if (p.extension(path).toLowerCase() == '.pdf') return _pdf(path);
    return Isolate.run(() {
      final ext = p.extension(path).toLowerCase();
      if (!supports(path)) {
        throw const FormatException(
          '不支援此格式；舊版 PPT、XLS、DOC 請另存為 PPTX、XLSX、DOCX',
        );
      }
      final file = File(path);
      final stat = file.statSync();
      if (stat.size > maxBytes(path)) {
        throw FormatException(
          officeExtensions.contains(ext) ? '文件超過 50 MB' : '文字或程式檔超過 256 KB',
        );
      }
      if (!officeExtensions.contains(ext)) {
        return ProjectDocument(
          [DocumentSection('文件', file.readAsStringSync())],
          stat.modified,
          const [],
        );
      }
      try {
        return ext == '.pptx'
            ? _presentation(file.readAsBytesSync(), stat.modified)
            : _office(file.readAsBytesSync(), stat.modified, ext);
      } on FormatException {
        rethrow;
      } catch (_) {
        throw const FormatException('無法讀取 Office 文件，請確認未加密且檔案完整');
      }
    });
  }

  static Future<ProjectDocument> _pdf(String path) async {
    final stat = await File(path).stat();
    if (stat.size > maxPptxBytes) throw const FormatException('PDF 超過 50 MB');
    await pdfrxFlutterInitialize();
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(path);
      if (document.pages.length > 500) {
        throw const FormatException('PDF 超過 500 頁，請拆分文件');
      }
      final sections = <DocumentSection>[];
      final warnings = <String>['PDF 讀取文字層；未辨識圖片內容，複雜表格與多欄閱讀順序需核對。'];
      var total = 0;
      for (final page in document.pages) {
        final text = (await page.loadText())?.fullText.trim() ?? '';
        total += text.length;
        if (total > 2000000) throw const FormatException('PDF 文字過多，請拆分文件');
        if (text.isEmpty) {
          warnings.add('第 ${page.pageNumber} 頁沒有文字層，可能需要 OCR。');
        } else {
          sections.add(DocumentSection('PDF 第 ${page.pageNumber} 頁', text));
        }
      }
      return ProjectDocument(sections, stat.modified, warnings);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('PDF 無法讀取，請確認未加密且檔案完整');
    } finally {
      await document?.dispose();
    }
  }

  static ProjectDocument _office(
    List<int> bytes,
    DateTime modified,
    String ext,
  ) {
    final archive = ZipDecoder().decodeBytes(bytes);
    var total = 0;
    XmlDocument? xml(String name) {
      final entry = archive.findFile(name);
      if (entry == null) return null;
      total += entry.size;
      if (entry.size > 8 * 1024 * 1024 || total > 24 * 1024 * 1024) {
        throw const FormatException('文件 XML 過大，請拆分');
      }
      final content = entry.readBytes();
      if (content == null) throw const FormatException('文件內容無法解壓縮');
      return XmlDocument.parse(utf8.decode(content));
    }

    Iterable<XmlElement> elements(XmlNode node, String local) => node
        .descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == local);
    final sections = <DocumentSection>[];
    if (ext == '.docx') {
      final body = xml('word/document.xml');
      if (body == null) throw const FormatException('不是有效的 DOCX');
      var i = 0;
      for (final paragraph in elements(body, 'p')) {
        final value = elements(
          paragraph,
          't',
        ).map((e) => e.innerText).join().trim();
        if (value.isNotEmpty) {
          sections.add(DocumentSection('Word 段落 ${++i}', value));
        }
      }
      return ProjectDocument(sections, modified, [
        'Word 讀取本文與表格段落；未辨識圖片、頁首頁尾或追蹤修訂語意。段落位置不是列印頁碼。',
      ]);
    }
    final workbook = xml('xl/workbook.xml');
    final rels = xml('xl/_rels/workbook.xml.rels');
    if (workbook == null || rels == null) {
      throw const FormatException('不是有效的 XLSX');
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
      if (part == null) throw const FormatException('Excel 工作表內容遺失');
      final sheetName = sheet.getAttribute('name') ?? '工作表';
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
            cells.add(
              '${cell.getAttribute('r') ?? ''}: $value${formula == null ? '' : '（公式 =$formula；此值為檔案快取，未重算）'}',
            );
          }
        }
        if (cells.isNotEmpty) {
          final values = cells.join(' | ');
          sections.add(
            DocumentSection(
              '工作表「$sheetName」· 第 ${row.getAttribute('r') ?? '?'} 列',
              firstRow == null ? values : '首個非空列（可能為欄名，需核對）：$firstRow\n$values',
            ),
          );
          firstRow ??= values;
        }
      }
    }
    return ProjectDocument(sections, modified, [
      'Excel 讀取儲存格原值與公式快取，不執行公式；日期可能呈現序號，未套用數字格式、圖表或圖片。',
    ]);
  }

  static ProjectDocument _presentation(List<int> bytes, DateTime modified) {
    final archive = ZipDecoder().decodeBytes(bytes);
    var xmlBytes = 0;
    XmlDocument? xml(String path) {
      final entry = archive.findFile(path);
      if (entry == null) return null;
      xmlBytes += entry.size;
      if (entry.size > 2 * 1024 * 1024 || xmlBytes > 16 * 1024 * 1024) {
        throw const FormatException('PPTX XML 內容過大，請拆分簡報');
      }
      final content = entry.readBytes();
      if (content == null) throw const FormatException('PPTX 內容無法解壓縮');
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
    if (presentation == null) throw const FormatException('不是有效的 PPTX 簡報');
    final slides = relationships('ppt/presentation.xml', 'slide');
    final ids = elements(presentation, 'sldId').toList();
    if (ids.length > 300) throw const FormatException('簡報超過 300 頁，請拆分後選取');
    final sections = <DocumentSection>[];
    final warnings = <String>[
      'PPTX 僅讀取可選取文字、表格文字與講者備忘稿；圖片、圖表數值、SmartArt 與嵌入物件尚未辨識。',
    ];
    for (var i = 0; i < ids.length; i++) {
      final ref = ids[i].attributes
          .where((a) => a.name.local == 'id' && a.name.prefix != null)
          .firstOrNull
          ?.value;
      final path = slides[ref];
      final slide = path == null ? null : xml(path);
      if (slide == null) throw FormatException('第 ${i + 1} 頁的內容遺失');
      final body = text(slide);
      if (body.isNotEmpty) {
        sections.add(DocumentSection('投影片第 ${i + 1} 頁', body));
      }
      var notesText = '';
      for (final notePath in relationships(path!, 'notesSlide').values) {
        final notes = xml(notePath);
        if (notes != null) notesText += '${text(notes, notes: true)}\n';
      }
      if (notesText.trim().isNotEmpty) {
        sections.add(
          DocumentSection('投影片第 ${i + 1} 頁 · 講者備忘稿', notesText.trim()),
        );
      }
      if (body.isEmpty && notesText.trim().isEmpty) {
        warnings.add('第 ${i + 1} 頁沒有可擷取文字。');
      }
    }
    return ProjectDocument(sections, modified, warnings);
  }
}
