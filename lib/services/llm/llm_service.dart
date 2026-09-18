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
    bool jsonObject = false,
  }) async {
    if (!settings.hasLlm) {
      return _demoAnswer();
    }

    final uri = Uri.parse('$openaiApiBaseUrl/chat/completions');
    final body = <String, dynamic>{
      'model': settings.chatModel,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    };
    if (jsonObject) {
      body['response_format'] = {'type': 'json_object'};
    }
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${settings.openaiApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
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
    required List<TranscriptLine> recent,
    required String trigger,
    String projectContext = '',
  }) {
    final transcript = recent
        .map((line) => '${line.speaker}：${line.text}')
        .join('\n');
    final project = projectContext.trim().isEmpty
        ? '（尚未選定專案資料夾。沒有規格、WBS、Issue 時，禁止編造時程與承諾。）'
        : projectContext.trim();
    return complete(
      system: suggestionSystemPrompt,
      user:
          '''
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
        .map(
          (line) => '[${_formatMs(line.startMs)}] ${line.speaker}：${line.text}',
        )
        .join('\n');
    final noteText = notes.isEmpty
        ? '（沒有現場筆記）'
        : notes.map((note) => '- ${note.text}').join('\n');

    if (!settings.hasLlm) {
      return _localMinutes(meeting: meeting, lines: lines, notes: notes);
    }

    final raw = await complete(
      system: '''
你是會議紀錄秘書。只輸出一個 JSON 物件，不要 Markdown 圍欄，也不要逐字稿陣列。
JSON 結構：
{
  "title": "精煉標題",
  "minutesMarkdown": "繁體中文 Markdown，含 ## 摘要、## 討論重點、## 決議、## 待辦。逐字稿有人報名就用真名。",
  "speakerNames": {"我": "可選真名", "對方A": "Casey", "對方B": "Lisa"}
}
規則：
- minutesMarkdown 必須是給人看的會議紀錄，不是 JSON
- 不要輸出 lines
- 若超過兩位對方，用對方C、對方D，或改成他們的名字
- 無法判斷就維持對方A／對方B，不要把不同人併成同一個「對方」
- speakerNames 只供會議紀錄參考，不會覆寫原始逐字稿
- 不要發明逐字稿裡沒有的事實''',
      user:
          '''
會議開始時間：${meeting.startedAt.toIso8601String()}
現場筆記：
$noteText

專案資料：
$projectContext

逐字稿：
$transcript''',
      temperature: 0.2,
      jsonObject: true,
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
    final markdown =
        '''
# ${meeting.title}

## 摘要
（尚未設定 OpenAI 金鑰，以下保留現場筆記與逐字稿，未產生 AI 摘要。）

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
    try {
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      final title = (json['title'] as String?)?.trim();
      final markdown =
          readableMinutesMarkdown(json['minutesMarkdown'] as String? ?? '') ??
          (json['minutesMarkdown'] as String?)?.trim();
      return MinutesResult(
        title: (title == null || title.isEmpty) ? fallbackTitle : title,
        minutesMarkdown: (markdown != null && markdown.isNotEmpty)
            ? markdown
            : '# $fallbackTitle\n\n（無法產生會議紀錄）',
        relabeled: lines,
      );
    } catch (_) {
      final recovered = readableMinutesMarkdown(raw);
      return MinutesResult(
        title: fallbackTitle,
        minutesMarkdown:
            recovered ?? (raw.trim().isEmpty ? '# $fallbackTitle' : raw.trim()),
        relabeled: lines,
      );
    }
  }

  /// Turns a stored blob into human markdown, including older broken JSON dumps.
  static String? readableMinutesMarkdown(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('{') && !trimmed.contains('"minutesMarkdown"')) {
      return trimmed;
    }
    try {
      final json = jsonDecode(_extractJson(trimmed)) as Map<String, dynamic>;
      final markdown = (json['minutesMarkdown'] as String?)?.trim();
      if (markdown != null &&
          markdown.isNotEmpty &&
          !markdown.trimLeft().startsWith('{')) {
        return markdown;
      }
    } catch (_) {}
    return _fallbackMinutesMarkdown(trimmed);
  }

  static String? _fallbackMinutesMarkdown(String raw) {
    const key = '"minutesMarkdown"';
    final keyAt = raw.indexOf(key);
    if (keyAt < 0) return null;
    final colon = raw.indexOf(':', keyAt + key.length);
    if (colon < 0) return null;
    var i = colon + 1;
    while (i < raw.length && raw[i].trim().isEmpty) {
      i++;
    }
    if (i >= raw.length || raw[i] != '"') return null;
    i++;
    final buffer = StringBuffer();
    while (i < raw.length) {
      final ch = raw[i];
      if (ch == '\\' && i + 1 < raw.length) {
        final next = raw[i + 1];
        buffer.write(switch (next) {
          'n' => '\n',
          't' => '\t',
          'r' => '\r',
          '"' => '"',
          '\\' => '\\',
          _ => next,
        });
        i += 2;
        continue;
      }
      if (ch == '"') break;
      if (ch == '\n') {
        final rest = raw.substring(i);
        if (RegExp(r'^\n\s*"(speakers|lines|speakerNames)"').hasMatch(rest)) {
          break;
        }
      }
      buffer.write(ch);
      i++;
    }
    final markdown = buffer.toString().trim();
    if (markdown.isEmpty || markdown.startsWith('{')) return null;
    return markdown;
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
