import 'dart:convert';
import 'dart:io';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class FakeProjectMeetings implements MeetingRepository {
  final List<Meeting> meetings = [];
  final List<TranscriptLine> lines = [];
  final List<Note> notes = [];
  String? requestedProject;

  @override
  Future<List<Meeting>> list({
    String? projectId,
    bool unassignedOnly = false,
  }) async {
    requestedProject = projectId;
    return meetings; // Deliberately return other projects to test the boundary.
  }

  @override
  Future<List<TranscriptLine>> listLines(String meetingId) async =>
      lines.where((line) => line.meetingId == meetingId).toList();

  @override
  Future<List<Note>> listNotes(String meetingId) async =>
      notes.where((note) => note.meetingId == meetingId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KnowledgeDoc doc(String path, {bool included = true}) => KnowledgeDoc(
  relativePath: path,
  kind: KnowledgeKind.spec,
  byteLength: 100,
  included: included,
  score: 1,
);

Meeting meeting(String id, String projectId, DateTime date) => Meeting(
  id: id,
  projectId: projectId,
  title: '週會',
  startedAt: date,
  status: MeetingStatus.completed,
);

TranscriptLine line(
  String id,
  String meetingId,
  String text, {
  bool finalText = true,
  int startMs = 65000,
}) => TranscriptLine(
  id: id,
  meetingId: meetingId,
  text: text,
  speaker: '小明',
  speakerIndex: 0,
  isFinal: finalText,
  startMs: startMs,
  endMs: startMs + 1000,
);

void main() {
  late Directory folder;
  late FakeProjectMeetings repo;
  late ProjectPack pack;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('cloakly-rag-');
    repo = FakeProjectMeetings();
    pack = ProjectPack(
      id: 'p1',
      name: '測試專案',
      folderPath: folder.path,
      indexedAt: DateTime(2026),
      docs: [],
    );
  });
  tearDown(() async => folder.delete(recursive: true));

  test(
    'finds Chinese decision, adjacent deadline, and excludes other projects and provisional speech',
    () async {
      repo.meetings.addAll([
        meeting('m1', 'p1', DateTime(2026, 9, 1)),
        meeting('m2', 'p2', DateTime(2026, 9, 2)),
      ]);
      repo.lines.addAll([
        line('1', 'm1', '我們決定下個版本加入登入功能。'),
        line('2', 'm1', '由小明負責，預定週五交付。', startMs: 68000),
        line('3', 'm1', '登入密碼暫定秘密', finalText: false),
        line('4', 'm2', '登入另一專案秘密'),
      ]);
      final result = await ProjectRetrieval(repo).retrieve(pack, '哪次會議決定登入功能？');
      expect(repo.requestedProject, 'p1');
      expect(result.sources, isNotEmpty);
      final context = result.context(pack.name, ProjectQuestionMode.search);
      expect(context, contains('週五交付'));
      expect(context, contains('1:05'));
      expect(context, contains('2026-09-01'));
      expect(context, isNot(contains('秘密')));
      expect(
        result.sources.every((source) => source.meetingId == 'm1'),
        isTrue,
      );
    },
  );

  test(
    'discovers new nested files without saved selections and ignores stale outside paths',
    () async {
      await Directory(p.join(folder.path, 'docs')).create();
      await File(
        p.join(folder.path, 'docs', 'spec.md'),
      ).writeAsString('${'無關內容。' * 4000}\n登入採用 OAuth 規格');
      await File(p.join(folder.path, '.hidden.md')).writeAsString('登入私人秘密');
      pack = pack.copyWith(
        docs: [doc('.hidden.md'), doc('../outside.md'), doc('missing.md')],
      );
      final result = await ProjectRetrieval(repo).retrieve(pack, 'OAuth 登入');
      expect(result.sources.single.text, contains('OAuth'));
      expect(result.sources.single.location, endsWith('–2 行'));
      expect(
        result.context(pack.name, ProjectQuestionMode.search),
        isNot(contains('私人秘密')),
      );
    },
  );

  test(
    'unmatched question returns no evidence instead of unrelated recent records',
    () async {
      repo.meetings.add(meeting('m1', 'p1', DateTime(2026)));
      repo.lines.add(line('1', 'm1', '今天討論午餐便當。'));
      final result = await ProjectRetrieval(repo).retrieve(pack, 'OAuth');
      expect(result.sources, isEmpty);
    },
  );

  test(
    'overview favors recent evidence and preserves conflicting older promises',
    () async {
      repo.meetings.addAll([
        meeting('old', 'p1', DateTime(2026, 8)),
        meeting('new', 'p1', DateTime(2026, 9)),
      ]);
      repo.lines.addAll([
        line('1', 'old', '登入預定週五完成'),
        line('2', 'new', '登入延期，尚未完成'),
      ]);
      final result = await ProjectRetrieval(
        repo,
      ).retrieve(pack, '目前狀況', mode: ProjectQuestionMode.overview);
      expect(result.sources.first.meetingId, 'new');
      expect(result.sources.last.meetingId, 'old');
      final payload =
          jsonDecode(result.context(pack.name, ProjectQuestionMode.overview))
              as Map;
      expect(payload['coverage'], contains('不是完整即時狀態'));
    },
  );

  test('always searches both project files and meeting notes', () async {
    repo.meetings.add(meeting('m1', 'p1', DateTime(2026)));
    repo.notes.add(
      Note(id: 'n1', meetingId: 'm1', text: '登入筆記', createdAt: DateTime(2026)),
    );
    await File(p.join(folder.path, 'spec.md')).writeAsString('登入規格');
    final result = await ProjectRetrieval(repo).retrieve(pack, '登入');
    expect(result.sources.any((source) => source.text == '登入筆記'), isTrue);
    expect(result.sources.any((source) => source.text == '登入規格'), isTrue);
  });

  test('missing folder still permits meeting retrieval', () async {
    pack = pack.copyWith(
      folderPath: p.join(folder.path, 'gone'),
      docs: [doc('spec.md')],
    );
    repo.meetings.add(meeting('m1', 'p1', DateTime(2026)));
    repo.lines.add(line('1', 'm1', '登入尚未完成'));
    final result = await ProjectRetrieval(repo).retrieve(pack, '登入');
    expect(result.sources, hasLength(1));
    expect(result.warnings.join(), contains('資料夾無法讀取'));
  });

  test('citation validation rejects fabricated and missing source IDs', () {
    final evidence = ProjectEvidence(
      sources: [
        ProjectSource(
          projectId: 'p1',
          title: 'spec',
          location: '第 1 行',
          text: '登入',
          date: DateTime(2026),
          group: 'spec',
        ),
      ],
      warnings: [],
    );
    expect(evidence.citations('參考 [S1]。'), {0});
    expect(() => evidence.citations('完成 [S2]。'), throwsStateError);
    expect(() => evidence.citations('完成 [S0]。'), throwsStateError);
    expect(() => evidence.citations('完成。'), throwsStateError);
  });

  test('unconfigured direct AI does not fabricate a demo project answer', () {
    expect(
      () => DirectAiService(
        AppSettings.defaults(),
      ).answerProjectQuestion(question: '進度', evidence: '{}'),
      throwsStateError,
    );
  });
}
