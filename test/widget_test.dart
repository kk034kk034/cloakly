import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/services/detection/question_detector.dart';
import 'package:cloakly/services/llm/llm_service.dart';
import 'package:cloakly/services/project/project_indexer.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:cloakly/services/stt/whisper_stt.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('問題偵測能抓到中英文問句，並忽略附和', () {
    final detector = QuestionDetector();
    expect(detector.isQuestion('登入頁的錯誤率有下降嗎？'), isTrue);
    expect(detector.isQuestion('所以這個 API 預計什麼時候可以提供測試？'), isTrue);
    expect(detector.isQuestion('Can you walk me through the launch plan?'), isTrue);
    expect(detector.isQuestion('好'), isFalse);
    expect(detector.isBackchannel('嗯嗯'), isTrue);
  });

  test('專案檔名會分到 TPM 知識類別', () {
    expect(ProjectIndexer.kindFor('docs/api-spec.md').name, 'spec');
    expect(ProjectIndexer.kindFor('WBS.xlsx.md').name, 'wbs');
    expect(ProjectIndexer.kindFor('meeting-agenda.md').name, 'agenda');
    expect(ProjectIndexer.kindFor('known-issues.md').name, 'issue');
    expect(ProjectIndexer.kindFor('客戶承諾.md').name, 'commitment');
    expect(ProjectIndexer.kindFor('README.md').name, 'background');
  });

  test('雙音源發言人標籤', () {
    expect(speakerLabelFor(0), '我');
    expect(speakerLabelFor(1), '對方A');
    expect(speakerLabelFor(2), '對方B');
    expect(SpeakerId.label(lane: SttLane.room, diarized: 2), '發言人 3');
  });

  test('OpenAI diarized_json 會拆成對方A/B', () {
    final events = eventsFromOpenAiDiarizedJson(
      {
        'text': '進度如何 下週能上線嗎',
        'segments': [
          {'speaker': 'A', 'text': '進度如何'},
          {'speaker': 'B', 'text': '下週能上線嗎'},
        ],
      },
      lane: SttLane.remote,
    );
    expect(events.map((e) => '${e.speakerLabel}:${e.text}').toList(), [
      '對方A:進度如何',
      '對方B:下週能上線嗎',
    ]);
    expect(diarizedIndexFromSpeaker('C'), 2);
    expect(SpeakerId.label(lane: SttLane.remote, diarized: 2), '對方C');
    expect(diarizedIndexFromSpeaker('SPEAKER_01'), 1);
  });

  test('壞掉的會議紀錄 JSON 會抽出 Markdown', () {
    const raw = '''
{
  "title": "英語學習討論",
  "minutesMarkdown": "## 摘要
對方A 提到個別分享。

## 討論重點
- Casey、Lisa、Kate 分享學習經驗
",
  "speakers": [{"index": 0, "name": "對方A"}]
}
''';
    final markdown = MinutesResult.readableMinutesMarkdown(raw);
    expect(markdown, contains('Casey、Lisa、Kate'));
    expect(markdown, isNot(contains('"title"')));
  });

  test('會議紀錄產生的 speakerNames 不覆寫逐字稿人員配對', () {
    final lines = [
      const TranscriptLine(
        id: 'l1',
        meetingId: 'm1',
        speaker: '對方A',
        speakerIndex: 1,
        text: '下週能上線嗎？',
        isFinal: true,
        startMs: 0,
        endMs: 1000,
      ),
      const TranscriptLine(
        id: 'l2',
        meetingId: 'm1',
        speaker: '對方B',
        speakerIndex: 2,
        text: '文件還沒好。',
        isFinal: true,
        startMs: 1200,
        endMs: 2000,
      ),
    ];

    const raw = '''
{
  "title": "週會",
  "minutesMarkdown": "## 摘要\\nCasey 問上線時程。",
  "speakerNames": {"對方A": "Casey", "對方B": "Lisa"}
}
''';

    final result = MinutesResult.parse(
      raw,
      fallbackTitle: '原始標題',
      lines: lines,
    );

    expect(result.relabeled.map((line) => line.speaker), ['對方A', '對方B']);
  });

  test('時間格式', () {
    expect(formatDuration(const Duration(seconds: 75)), '01:15');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(
      formatElapsedSince(
        DateTime(2026, 9, 18, 10, 5, 23),
        DateTime(2026, 9, 18, 10, 0),
      ),
      '05:23',
    );
  });

  test('舊專案 JSON 沒有 id 時會用資料夾路徑當 id', () {
    final pack = ProjectPack.fromJson({
      'folderPath': r'C:\work\alpha',
      'name': 'alpha',
      'indexedAt': 0,
      'docs': const [],
    });
    expect(pack.id, r'C:\work\alpha');
    expect(pack.name, 'alpha');
  });

  test('會議可綁定專案，缺 project_id 視為未分類', () {
    final assigned = Meeting.fromMap({
      'id': 'm1',
      'title': '週會',
      'started_at': 0,
      'ended_at': null,
      'status': 'completed',
      'minutes_markdown': null,
      'audio_path': null,
      'listen_mode': 'meeting',
      'project_id': 'p1',
    });
    expect(assigned.projectId, 'p1');

    final legacy = Meeting.fromMap({
      'id': 'm2',
      'title': '舊會議',
      'started_at': 0,
      'ended_at': null,
      'status': 'completed',
      'minutes_markdown': null,
      'audio_path': null,
      'listen_mode': 'meeting',
    });
    expect(legacy.projectId, isNull);
  });
}
