import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

const unconfirmedEmailMessage = '請先到信箱點確認信，確認後才能登入。';

bool hostedEmailConfirmed(User user) {
  final email = user.email?.trim() ?? '';
  final confirmed = user.emailConfirmedAt?.trim() ?? '';
  return email.isNotEmpty && confirmed.isNotEmpty;
}

String hostedAuthErrorMessage(String raw) {
  final message = raw.toLowerCase();
  if (message.contains('email not confirmed') ||
      message.contains('not confirmed')) {
    return unconfirmedEmailMessage;
  }
  return raw;
}

String? hostedErrorCode(Object? details) {
  final map = switch (details) {
    final Map value => value,
    final String value => _jsonObject(value),
    _ => null,
  };
  final code = map?['error'];
  return code is String ? code : null;
}

String hostedQuotaMessage(Object? details, {required String fallback}) {
  final code = hostedErrorCode(details);
  return switch (code) {
    'FREE_POOL_EXHAUSTED' => '今天的免費會議名額已滿，請明天再試或升級 Pro。',
    'FREE_DAILY_LIMIT_REACHED' => '今天的免費會議額度已使用完畢。可到帳號與訂閱頁升級 Pro。',
    'FREE_QUESTION_LIMIT_REACHED' => '今天的免費專案問答已使用 5 次。',
    'FREE_PLAN_LIMIT_REACHED' => '今天的免費計畫建議已使用 5 次。',
    'DEVICE_FREE_ACCOUNT_IN_USE' => '這支手機今天已經使用過另一個帳號的免費額度。',
    'DEVICE_REQUIRED' => '無法確認這支手機，請更新 App 後再試。',
    'EMAIL_NOT_CONFIRMED' => unconfirmedEmailMessage,
    'MEETING_ALLOWANCE_REQUIRED' => '請先開始今天的會議，或升級 Pro。',
    'ALLOWANCE_RESERVATION_FAILED' =>
      '無法預約會議額度。若剛才開會中斷，請等幾分鐘再試；持續失敗請回報。',
    'TRANSCRIPTION_NOT_CONFIGURED' => '後端尚未設定轉寫服務。',
    'TRANSCRIPTION_PROVIDER_FAILED' => '轉寫服務暫時無法使用，請稍後再試。',
    'INTERNAL_ERROR' => '伺服器暫時發生錯誤，請稍後再試。',
    _ => code == null || code.isEmpty ? fallback : '$fallback（$code）',
  };
}

Map<String, dynamic>? _jsonObject(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}
