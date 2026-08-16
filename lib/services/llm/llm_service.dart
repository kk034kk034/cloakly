import 'dart:convert';

import 'package:cloakly/core/constants.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:http/http.dart' as http;

class LlmService {
  LlmService(this.settings);

  final AppSettings settings;

  bool get isConfigured => settings.hasLlm;

  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.4,
  }) async {
    if (!settings.hasLlm) {
      return _demoAnswer();
    }

    final uri = Uri.parse('$openaiApiBaseUrl/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${settings.openaiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': settings.chatModel,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('語言模型失敗：${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    final message = choices.first['message'] as Map<String, dynamic>;
    return (message['content'] as String).trim();
  }

  Future<String> suggestAnswer({
    required ListenMode mode,
    required List<TranscriptLine> recent,
    required String trigger,
    String projectContext = '',
  }) {
    final transcript = recent
        .map((line) => '${line.speaker}：${line.text}')
        .join('\n');
    final personal = settings.personalContext.trim().isEmpty
        ? '（未填個人背景）'
        : settings.personalContext.trim();
    final project = projectContext.trim().isEmpty
        ? '（尚未選定專案資料夾。沒有規格、WBS、Issue 時，禁止編造時程與承諾。）'
        : projectContext.trim();
    return complete(
      system: mode.systemPrompt,
      user: '''
個人背景：
$personal

專案資料（會議前選定的資料夾，回答必須以此為準）：
$project

近期對話：
$transcript

觸發內容：
$trigger

輸出格式：
建議回答：<一句可說出口的話>
要點：
- …
若資料不足，寫「不要承諾…」以及建議怎麼把問題帶回內部確認。不要前言。''',
    );
  }

  Future<MinutesResult> generateMinutes({
    required Meeting meeting,
    required List<TranscriptLine> lines,
    required List<Note> notes,
    String projectContext = '',
  }) async {
    final transcript = lines
        .map((line) => '[${_formatMs(line.startMs)}] ${line.speaker}：${line.text}')
        .join('\n');
    final noteText = notes.isEmpty
        ? '（沒有現場筆記）'
        : notes.map((note) => '- ${note.text}').join('\n');

    if (!settings.hasLlm) {
      return _localMinutes(
        meeting: meeting,
        lines: lines,
        notes: notes,
      );
    }

    final raw = await complete(
      system: '''
你是會議紀錄秘書。請只輸出一段 JSON，不要 Markdown 圍欄。
JSON 結構：
{
  "title": "精煉標題",
  "minutesMarkdown": "繁體中文 Markdown 會議紀錄，含摘要、討論重點、決議、待辦（負責人/期限若可判斷）",
  "speakers": [{"index": 0, "name": "發言人名稱"}],
  "lines": [{"id": "原本的id", "speakerIndex": 0, "speaker": "名稱"}]
}
規則：
- 盡力把同一個人合併。已標成「我／對方A／對方B／發言人 1」的請保留，不要把對方A和對方B併成一個「對方」
- lines 必須覆蓋所有傳入的 id
- 不要發明逐字稿內容''',
      user: '''
會議開始時間：${meeting.startedAt.toIso8601String()}
現場筆記：
$noteText

專案資料：
$projectContext

逐字稿：
$transcript''',
      temperature: 0.2,
    );

    return MinutesResult.parse(raw, fallbackTitle: meeting.title, lines: lines);
  }

  MinutesResult _localMinutes({
    required Meeting meeting,
    required List<TranscriptLine> lines,
    required List<Note> notes,
  }) {
    final noteBlock = notes.isEmpty
        ? '- （沒有現場筆記）'
        : notes.map((note) => '- ${note.text}').join('\n');
    final transcript = lines
        .map((line) => '- **${line.speaker}**：${line.text}')
        .join('\n');
    final markdown = '''
# ${meeting.title}

## 摘要
（示範模式：填入 API 金鑰後會自動整理討論重點、決議與待辦。）

## 現場筆記
$noteBlock

## 依發言人的逐字稿
$transcript
''';
    return MinutesResult(
      title: meeting.title,
      minutesMarkdown: markdown.trim(),
      relabeled: lines,
    );
  }

  String _demoAnswer() {
    return '''【示範提示】尚未設定 API 金鑰時，會顯示這種範本。

建議開場：
「我先確認一下你的問題，再補上目前掌握的數字。」

可以說的要點：
1. 先複述問題，避免答錯題
2. 給 1 個具體現況，不確定的標「會後補」
3. 主動說下一步與時間

到設定頁填入 OpenAI API 金鑰後，提示會依真實對話產生。''';
  }

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class MinutesResult {
  const MinutesResult({
    required this.title,
    required this.minutesMarkdown,
    required this.relabeled,
  });

  final String title;
  final String minutesMarkdown;
  final List<TranscriptLine> relabeled;

  factory MinutesResult.parse(
    String raw, {
    required String fallbackTitle,
    required List<TranscriptLine> lines,
  }) {
    final jsonText = _extractJson(raw);
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      final title = (json['title'] as String?)?.trim();
      final markdown = (json['minutesMarkdown'] as String?)?.trim();
      final updates = <String, ({int index, String speaker})>{};
      final lineRows = json['lines'] as List<dynamic>? ?? const [];
      for (final row in lineRows) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String?;
        if (id == null) continue;
        updates[id] = (
          index: (map['speakerIndex'] as num?)?.toInt() ?? 0,
          speaker: (map['speaker'] as String?) ?? '發言人',
        );
      }
      final relabeled = lines.map((line) {
        final update = updates[line.id];
        if (update == null) return line;
        return line.copyWith(
          speakerIndex: update.index,
          speaker: update.speaker,
        );
      }).toList();
      return MinutesResult(
        title: (title == null || title.isEmpty) ? fallbackTitle : title,
        minutesMarkdown: markdown?.isNotEmpty == true
            ? markdown!
            : '# $fallbackTitle\n\n（無法產生會議紀錄）',
        relabeled: relabeled,
      );
    } catch (_) {
      return MinutesResult(
        title: fallbackTitle,
        minutesMarkdown: raw.trim().isEmpty ? '# $fallbackTitle' : raw.trim(),
        relabeled: lines,
      );
    }
  }

  static String _extractJson(String raw) {
    final trimmed = raw.trim();
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = fenced.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }
    return trimmed;
  }
}
