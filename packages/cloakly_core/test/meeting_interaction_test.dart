import 'dart:io';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/project/project_context_builder.dart';
import 'package:cloakly_core/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine line(int i, {bool finalText = true}) => TranscriptLine(
  id: '$i',
  meetingId: 'meeting',
  speaker: '發言人 ${i % 5 + 1}',
  speakerIndex: i % 5,
  text: '第 $i 段發言：這個研究問題應該如何處理？',
  isFinal: finalText,
  startMs: i * 1000,
  endMs: i * 1000 + 900,
);

void main() {
  testWidgets(
    'live transcript follows latest, allows review and returns to latest',
    (tester) async {
      var lines = List.generate(60, line);
      Future<void> render() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TranscriptList(lines: lines, followLatest: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render();
      expect(find.text(lines.last.text).hitTestable(), findsOneWidget);
      lines = [...lines, line(60)];
      await render();
      expect(find.text(lines.last.text).hitTestable(), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('回到最新'), findsOneWidget);
      lines = [...lines, line(61)];
      await render();
      expect(find.text('回到最新'), findsOneWidget);
      await tester.tap(find.text('回到最新'));
      await tester.pumpAndSettle();
      expect(find.text(lines.last.text).hitTestable(), findsOneWidget);
      expect(find.text('回到最新'), findsNothing);
      lines = [...lines.take(61), line(62, finalText: false)];
      await render();
      expect(find.text(lines.last.text).hitTestable(), findsOneWidget);
    },
  );

  testWidgets('only finalized utterances can be selected', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptList(
            lines: [line(0), line(1, finalText: false)],
            onToggle: selected.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text(line(0).text));
    await tester.tap(find.text(line(1).text));
    expect(selected, {'0'});
    expect(find.textContaining('暫定'), findsOneWidget);
  });

  test('project background and terms round trip and stay isolated', () async {
    final folder = await Directory.systemTemp.createTemp(
      'cloakly-project-test',
    );
    addTearDown(() => folder.delete(recursive: true));
    final first = ProjectPack(
      id: 'a',
      folderPath: folder.path,
      name: '博士研究',
      indexedAt: DateTime(2026),
      docs: [],
      personalContext: '我是博士生',
      transcriptionTerms: 'LoRA',
    );
    final saved = ProjectPack.fromJson(first.toJson());
    expect(saved.personalContext, first.personalContext);
    expect(saved.transcriptionTerms, first.transcriptionTerms);
    final second = ProjectPack(
      id: 'b',
      folderPath: folder.path,
      name: '工作',
      indexedAt: DateTime(2026),
      docs: [],
      personalContext: '我是設計師',
    );
    final builder = ProjectContextBuilder();
    expect(await builder.build(saved), contains('我是博士生'));
    expect(await builder.build(second), isNot(contains('我是博士生')));
    final legacy = Map<String, Object?>.from(first.toJson())
      ..remove('personalContext')
      ..remove('transcriptionTerms');
    expect(ProjectPack.fromJson(legacy).personalContext, isEmpty);
  });
}
