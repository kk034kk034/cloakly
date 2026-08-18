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

  test('時間格式', () {
    expect(formatDuration(const Duration(seconds: 75)), '01:15');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
