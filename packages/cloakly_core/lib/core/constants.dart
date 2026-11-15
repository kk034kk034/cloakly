import 'package:cloakly_core/l10n/cloakly_locale.dart';

enum AutoTrigger { questions, pause, off }

enum Pace { fast, balanced, relaxed }

extension AutoTriggerX on AutoTrigger {
  String get label {
    final l10n = CloaklyLocale.strings;
    return switch (this) {
      AutoTrigger.questions => l10n.triggerQuestions,
      AutoTrigger.pause => l10n.triggerPause,
      AutoTrigger.off => l10n.triggerOff,
    };
  }

  String get hint {
    final l10n = CloaklyLocale.strings;
    return switch (this) {
      AutoTrigger.questions => l10n.triggerQuestionsHint,
      AutoTrigger.pause => l10n.triggerPauseHint,
      AutoTrigger.off => l10n.triggerOffHint,
    };
  }
}

String suggestionSystemPrompt() =>
    '''
${llmOutputLanguageRule()}
你是會議即時助理。根據「專案資料」與「現場逐字稿」草擬使用者可以立刻說出口的回答。
規則：
- 只能用專案資料與對話裡出現的事實；沒寫的時程、數字、範圍禁止編造
- 客戶追問尚未確認的交付日或測試日時，明確提示不要承諾確切日期，並給一句保守、可說的話
- 先給建議開場（一句），再列 2 到 4 個要點；需要會後確認的標出來
- 依此專案的角色與背景給建議；未提供角色時，不要假定使用者是 TPM、業務或研究生
- 針對使用者選取的發言回答；附近對話僅作上下文，不要改答別的問題
- 語氣清楚、不硬撐、不替他人承諾
''';

/// Prompt instruction only. Not an ARB string. Output follows
/// [CloaklyLocale.current], the effective in-app locale.
String llmOutputLanguageRule() {
  if (CloaklyLocale.current.languageCode == 'zh') {
    return '請使用繁體中文撰寫所有給使用者看的文字。標題與小標也用繁體中文。';
  }
  return 'Write every user-visible answer in English, including headings.';
}

extension PaceX on Pace {
  String get label {
    final l10n = CloaklyLocale.strings;
    return switch (this) {
      Pace.fast => l10n.paceFast,
      Pace.balanced => l10n.paceBalanced,
      Pace.relaxed => l10n.paceRelaxed,
    };
  }

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
