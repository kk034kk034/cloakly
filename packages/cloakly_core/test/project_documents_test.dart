import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/project/project_document_reader.dart';

import 'package:cloakly_core/services/project/project_indexer.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/services/project/project_context_builder.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'project_question_test.dart' as fixtures;

Future<File> zipFile(String path, Map<String, String> entries) async {
  final archive = Archive();
  for (final entry in entries.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return File(path).writeAsBytes(ZipEncoder().encode(archive));
}

Map<String, String> deck() => {
  'ppt/presentation.xml':
      '<p:presentation xmlns:p="p" xmlns:r="r"><p:sldIdLst><p:sldId id="200" r:id="second"/><p:sldId id="201" r:id="first"/></p:sldIdLst></p:presentation>',
  'ppt/_rels/presentation.xml.rels':
      '<Relationships><Relationship Id="first" Type="x/slide" Target="slides/slide1.xml"/><Relationship Id="second" Type="x/slide" Target="slides/slide2.xml"/></Relationships>',
  'ppt/slides/slide1.xml':
      '<p:sld xmlns:p="p" xmlns:a="a"><a:p><a:r><a:t>登入功能預計下週完成</a:t></a:r></a:p></p:sld>',
  'ppt/slides/slide2.xml':
      '<p:sld xmlns:p="p" xmlns:a="a"><a:p><a:r><a:t>研究背景 &amp; 實驗</a:t></a:r></a:p></p:sld>',
  'ppt/slides/_rels/slide1.xml.rels':
      '<Relationships><Relationship Id="n" Type="x/notesSlide" Target="../notesSlides/notesSlide7.xml"/></Relationships>',
  'ppt/notesSlides/notesSlide7.xml':
      '<p:notes xmlns:p="p" xmlns:a="a"><p:sp><p:ph type="body"/><a:p><a:r><a:t>口頭補充：驗證資料不足</a:t></a:r></a:p></p:sp><p:sp><p:ph type="sldNum"/><a:p><a:t>99</a:t></a:p></p:sp></p:notes>',
};

List<int> pdf(String text) {
  final stream = text.isEmpty ? '' : 'BT /F1 16 Tf 30 150 Td ($text) Tj ET';
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 200] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
  ];
  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final start = buffer.length;
  buffer.write('xref\n0 6\n0000000000 65535 f \n');
  for (final offset in offsets) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$start\n%%EOF');
  return ascii.encode(buffer.toString());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProjectPack pack;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cloakly-documents-');
    pack = ProjectPack(
      id: 'p1',
      folderPath: root.path,
      name: '研究',
      indexedAt: DateTime(2026),
      docs: [],
    );
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async => root.delete(recursive: true));

  test(
    'PPTX respects presentation order, decodes text, and reads matching speaker notes',
    () async {
      final file = await zipFile(p.join(root.path, '研究.pptx'), deck());
      final content = await ProjectDocumentReader().readFile(file.path);
      expect(content.sections[0].text, '研究背景 & 實驗');
      expect(content.sections[1].location, '投影片第 2 頁');
      expect(content.sections[2].text, '口頭補充：驗證資料不足');
      expect(content.sections.map((s) => s.text).join(), isNot(contains('99')));
      expect(content.warnings.join(), contains('圖片'));
      pack = pack.copyWith(docs: [fixtures.doc('研究.pptx')]);
      expect(await ProjectContextBuilder().build(pack), contains('投影片第 2 頁'));
    },
  );

  test(
    'progress retrieval includes deck and oral report with separate citations',
    () async {
      await zipFile(p.join(root.path, '研究.pptx'), deck());
      pack = pack.copyWith(docs: [fixtures.doc('研究.pptx')]);
      final repo = fixtures.FakeProjectMeetings();
      repo.meetings.add(fixtures.meeting('m1', 'p1', DateTime(2026, 9, 21)));
      repo.lines.add(fixtures.line('1', 'm1', '登入功能延期，測試尚未完成。'));
      final mode = ProjectRetrieval.modeFor(
        '目前我的專案進度如何？',
        ProjectQuestionMode.search,
      );
      expect(mode, ProjectQuestionMode.overview);
      final result = await ProjectRetrieval(
        repo,
      ).retrieve(pack, '目前我的專案進度如何？', mode: mode);
      expect(
        result.sources.any((s) => s.location.contains('投影片第 2 頁')),
        isTrue,
      );
      expect(
        result.sources.any((s) => s.meetingId == 'm1' && s.text.contains('延期')),
        isTrue,
      );
    },
  );

  test(
    'XLSX resolves shared strings, sheet names, coordinates and cached formula values',
    () async {
      final file = await zipFile(p.join(root.path, '進度.xlsx'), {
        'xl/workbook.xml':
            '<workbook xmlns:r="r"><sheets><sheet name="里程碑" r:id="r1"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels':
            '<Relationships><Relationship Id="r1" Target="worksheets/sheet3.xml"/></Relationships>',
        'xl/sharedStrings.xml': '<sst><si><t>登入功能</t></si></sst>',
        'xl/worksheets/sheet3.xml':
            '<worksheet><sheetData><row r="7"><c r="A7" t="s"><v>0</v></c><c r="B7" t="inlineStr"><is><t>待驗收</t></is></c><c r="C7"><f>1+2</f><v>3</v></c></row></sheetData></worksheet>',
      });
      final content = await ProjectDocumentReader().readFile(file.path);
      expect(content.sections.single.location, contains('里程碑'));
      expect(content.sections.single.text, contains('A7: 登入功能'));
      expect(content.sections.single.text, contains('B7: 待驗收'));
      expect(content.sections.single.text, contains('未重算'));
    },
  );

  test('DOCX reads body and table text with paragraph locations', () async {
    final file = await zipFile(p.join(root.path, '設計.docx'), {
      'word/document.xml':
          '<w:document xmlns:w="w"><w:body><w:p><w:r><w:t>研究目的</w:t></w:r></w:p><w:tbl><w:tr><w:tc><w:p><w:r><w:t>驗收條件</w:t></w:r></w:p></w:tc></w:tr></w:tbl></w:body></w:document>',
    });
    final content = await ProjectDocumentReader().readFile(file.path);
    expect(content.sections.map((s) => s.text), ['研究目的', '驗收條件']);
  });

  test(
    'PDF extracts a real text layer and warns for pages with no text',
    () async {
      Pdfrx.cacheDirectoryPath = root.path;
      final file = await File(
        p.join(root.path, 'progress.pdf'),
      ).writeAsBytes(pdf('Project progress: pending validation'));
      final content = await ProjectDocumentReader().readFile(file.path);
      expect(content.sections.single.location, 'PDF 第 1 頁');
      expect(content.sections.single.text, contains('pending validation'));
      await file.writeAsBytes(pdf(''));
      final empty = await ProjectDocumentReader().readFile(file.path);
      expect(empty.sections, isEmpty);
      expect(empty.warnings.join(), contains('OCR'));
    },
  );

  test(
    'scan automatically includes supported Office and code files and skips dependencies',
    () async {
      for (final name in [
        'README.md',
        'research.pptx',
        'plan.xlsx',
        'notes.pdf',
        'notes.docx',
        'lib/app.dart',
        'android/src/Main.kt',
        'Dockerfile',
        'node_modules/x.js',
        '.env',
        '.hidden/a.py',
      ]) {
        final file = File(p.join(root.path, name));
        await file.parent.create(recursive: true);
        await file.writeAsString('example');
      }
      final scanned = await ProjectIndexer().index(root.path);
      expect(scanned.docs, hasLength(8));
      expect(scanned.includedCount, 8);
    },
  );

  test(
    'rescan automatically includes new files placed in project folder',
    () async {
      await File(p.join(root.path, 'README.md')).writeAsString('背景');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(projectsProvider.future);
      final notifier = container.read(projectsProvider.notifier);
      await notifier.indexFolder(root.path);
      final project = container.read(projectsProvider).requireValue.active!;
      await File(p.join(root.path, 'spec.md')).writeAsString('新規格');
      await notifier.reindex(project.id);
      expect(
        container.read(projectsProvider).requireValue.active!.includedCount,
        2,
      );
    },
  );

  test(
    'malformed Office and unsupported old Office formats return clear errors',
    () async {
      final bad = await File(
        p.join(root.path, 'broken.pptx'),
      ).writeAsString('not a zip');
      await expectLater(
        ProjectDocumentReader().readFile(bad.path),
        throwsFormatException,
      );
      await expectLater(
        ProjectDocumentReader().readFile(p.join(root.path, 'old.ppt')),
        throwsFormatException,
      );
    },
  );
}
