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
  return switch (hostedErrorCode(details)) {
    'FREE_POOL_EXHAUSTED' => '今天的免費會議名額已滿，請明天再試或升級 Pro。',
    'FREE_DAILY_LIMIT_REACHED' => '今天的免費會議額度已使用完畢。可到帳號與訂閱頁升級 Pro。',
    'FREE_QUESTION_LIMIT_REACHED' => '今天的免費專案問答已使用 5 次。',
    'FREE_PLAN_LIMIT_REACHED' => '今天的免費計畫建議已使用 5 次。',
    'DEVICE_FREE_ACCOUNT_IN_USE' => '這支手機今天已經使用過另一個帳號的免費額度。',
    'DEVICE_REQUIRED' => '無法確認這支手機，請更新 App 後再試。',
    'EMAIL_NOT_CONFIRMED' => unconfirmedEmailMessage,
    'MEETING_ALLOWANCE_REQUIRED' => '請先開始今天的會議，或升級 Pro。',
    _ => fallback,
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
