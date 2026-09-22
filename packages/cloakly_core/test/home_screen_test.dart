import 'package:cloakly_core/app.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Projects extends ProjectsNotifier {
  @override
  Future<ProjectLibrary> build() async => ProjectLibrary(
    activeId: 'p1',
    projects: [
      ProjectPack(
        id: 'p1',
        folderPath: '/project',
        name: 'alpha',
        indexedAt: DateTime(2026),
        docs: const [],
      ),
    ],
  );
}

class _Meetings extends MeetingsNotifier {
  @override
  Future<List<Meeting>> build() async => [
    for (var i = 1; i <= 8; i++)
      Meeting(
        id: 'm$i',
        title: '週會 $i',
        startedAt: DateTime(2026, 9, i),
        status: MeetingStatus.completed,
      ),
  ];
}

void main() {
  testWidgets('專案內頁直接呈現問答與開始會議，會議紀錄進新頁', (tester) async {
    final router = createAppRouter(initialLocation: '/home');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith(_Projects.new),
          meetingsProvider.overrideWith(_Meetings.new),
          demoModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('開始會議'), findsOneWidget);
    expect(find.text('專案問答'), findsOneWidget);
    expect(find.text('專案狀態'), findsOneWidget);
    expect(find.text('會議紀錄'), findsOneWidget);
    expect(find.textContaining('8 場'), findsOneWidget);
    expect(find.text('週會 1'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('例如：哪次會議決定加入登入功能？'), findsOneWidget);
    expect(find.textContaining('Enter 送出'), findsOneWidget);

    await tester.tap(find.text('會議紀錄'));
    await tester.pumpAndSettle();
    expect(find.text('週會 1'), findsOneWidget);
    expect(find.textContaining('會議紀錄'), findsWidgets);
  });
}
