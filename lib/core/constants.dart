enum AutoTrigger {
  questions,
  pause,
  off,
}

enum ListenMode {
  meeting,
  interview,
  sales,
  translate,
}

enum Pace {
  fast,
  balanced,
  relaxed,
}

extension AutoTriggerX on AutoTrigger {
  String get label => switch (this) {
        AutoTrigger.questions => '偵測到問題',
        AutoTrigger.pause => '每次停頓',
        AutoTrigger.off => '關閉',
      };

  String get hint => switch (this) {
        AutoTrigger.questions => '對方提問後，自動草擬你可以說的回答',
        AutoTrigger.pause => '對話告一段落時，整理重點或建議下句',
        AutoTrigger.off => '只在你按下「給我提示」時才產生建議',
      };
}

extension ListenModeX on ListenMode {
  String get label => switch (this) {
        ListenMode.meeting => '會議',
        ListenMode.interview => '面試',
        ListenMode.sales => '業務',
        ListenMode.translate => '翻譯',
      };

  String get systemPrompt => switch (this) {
        ListenMode.meeting => '''
你是 TPM 會議即時助理。根據「專案資料」與「現場逐字稿」草擬使用者可以立刻說出口的回答。
規則：
- 只能用專案資料與對話裡出現的事實；沒寫的時程、數字、範圍禁止編造
- 客戶追問尚未確認的交付日或測試日時，明確提示「不要承諾確切日期」，並給一句保守、可說的話
- 先給建議開場（一句），再列 2 到 4 個要點；需要會後確認的標出來
- 語氣像現場 TPM：清楚、不硬撐、不替 RD 承諾''',
        ListenMode.interview => '''
你是面試即時助理。當對方提問時，草擬第一人稱、具體、有結構的回答。
規則：
- 能用 STAR（情境、任務、行動、結果）就用
- 不要編造成績或職稱；不確定就建議誠實、具體的講法
- 回答要能在 30 到 60 秒內說完
- 先給一句開場，再列要點''',
        ListenMode.sales => '''
你是業務通話助理。根據對方的問題或異議，草擬自然、不硬銷的回應。
規則：
- 先同理再對應價值，避免誇大
- 不確定價格或時程就標「需向內部確認」
- 給一句可說的開場，以及 2 到 4 個要點或反問''',
        ListenMode.translate => '''
你是即時翻譯助理。把對方剛說的內容翻成使用者的語言，並補一句建議回覆。
輸出格式：
1) 翻譯
2) 建議回覆（一句口語）''',
      };
}

extension PaceX on Pace {
  String get label => switch (this) {
        Pace.fast => '快速',
        Pace.balanced => '均衡',
        Pace.relaxed => '從容',
      };

  Duration get quietWindow => switch (this) {
        Pace.fast => const Duration(milliseconds: 1000),
        Pace.balanced => const Duration(milliseconds: 1500),
        Pace.relaxed => const Duration(milliseconds: 2500),
      };

  Duration get minGap => switch (this) {
        Pace.fast => const Duration(seconds: 5),
        Pace.balanced => const Duration(seconds: 15),
        Pace.relaxed => const Duration(seconds: 40),
      };
}

const sampleRate = 16000;
const numChannels = 1;
const pcmBytesPerSecond = sampleRate * numChannels * 2;

const openaiApiBaseUrl = 'https://api.openai.com/v1';
const openaiTranscribeModel = 'gpt-4o-mini-transcribe';
const openaiDiarizeModel = 'gpt-4o-transcribe-diarize';
