import 'dart:async';

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/project/project_question_screen.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'project_question_test.dart' as fixtures;

class TestProjects extends ProjectsNotifier {
  @override
  Future<ProjectLibrary> build() async => ProjectLibrary(
    activeId: 'p2',
    projects: [
      for (final id in ['p1', 'p2'])
        ProjectPack(
          id: id,
          folderPath: '/project',
          name: id,
          indexedAt: DateTime(2026),
          docs: [],
        ),
    ],
  );
}

class TestAi implements AiService {
  int calls = 0;
  String? evidence;
  Completer<String>? pending;

  @override
  bool get isConfigured => true;

  @override
  Future<AiTextResult> answerProjectQuestion({
    required String question,
    required String evidence,
  }) async {
    calls++;
    this.evidence = evidence;
    return AiTextResult(
      pending == null ? '登入尚未完成 [S1]。' : await pending!.future,
      usage: const AiUsage(
        model: 'gpt-4o-mini',
        inputTokens: 1000,
        outputTokens: 100,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestRetrieval extends ProjectRetrieval {
  TestRetrieval(super.repository);

  String? projectId;

  @override
  Future<ProjectEvidence> retrieve(
    ProjectPack pack,
    String question, {
    ProjectQuestionMode mode = ProjectQuestionMode.search,
  }) async {
    projectId = pack.id;
    if (question == 'OAuth') {
      return const ProjectEvidence(sources: [], warnings: []);
    }
    return ProjectEvidence(
      sources: [
        ProjectSource(
          projectId: pack.id,
          title: '2026-09-21 週會',
          location: '逐字稿 1:05–1:06',
          text: '[1:05] 小明：登入尚未完成',
          date: DateTime(2026, 9, 21),
          group: 'meeting:m1',
          meetingId: 'm1',
        ),
      ],
      warnings: const [],
    );
  }
}

void main() {
  late fixtures.FakeProjectMeetings repo;
  late TestAi ai;
  late TestRetrieval retrieval;
  setUp(() {
    repo = fixtures.FakeProjectMeetings();
    repo.meetings.add(fixtures.meeting('m1', 'p1', DateTime(2026, 9, 21)));
    repo.lines.add(fixtures.line('1', 'm1', '登入尚未完成'));
    ai = TestAi();
    retrieval = TestRetrieval(repo);
  });

  Future<void> render(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith(TestProjects.new),
          meetingRepositoryProvider.overrideWithValue(repo),
          projectRetrievalProvider.overrideWithValue(retrieval),
          aiServiceProvider.overrideWithValue(ai),
        ],
        child: const MaterialApp(home: ProjectQuestionScreen(projectId: 'p1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submitQuestion(WidgetTester tester) async {
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('pins project scope and opens cited transcript snapshot', (
    tester,
  ) async {
    await render(tester);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.textContaining('所有支援文件'), findsOneWidget);
    expect(find.textContaining('全部會議、逐字稿與筆記'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '登入');
    await submitQuestion(tester);
    expect(retrieval.projectId, 'p1');
    expect(ai.calls, 1);
    expect(ai.evidence, contains('登入尚未完成'));
    expect(find.textContaining('本次 AI 用量'), findsOneWidget);
    final source = find.widgetWithIcon(ListTile, Icons.source_outlined);
    await tester.ensureVisible(source);
    await tester.tap(source);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('[1:05] 小明：登入尚未完成'), findsOneWidget);
    expect(find.text('開啟會議'), findsOneWidget);
  });

  testWidgets('no match avoids AI and explains missing evidence', (
    tester,
  ) async {
    await render(tester);
    await tester.enterText(find.byType(TextField), 'OAuth');
    await submitQuestion(tester);
    expect(ai.calls, 0);
    expect(
      find.textContaining('目前檢索資料不足以確認', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets(
    'failure retains question for retry and disposal ignores in-flight response',
    (tester) async {
      ai.pending = Completer<String>();
      await render(tester);
      await tester.enterText(find.byType(TextField), '登入');
      await submitQuestion(tester);
      ai.pending!.complete('錯誤引用 [S99]');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('無法完成問答'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '登入',
      );
      ai.pending = Completer<String>();
      await submitQuestion(tester);
      await tester.pumpWidget(const SizedBox());
      ai.pending!.complete('來源 [S1]');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    },
  );
}
