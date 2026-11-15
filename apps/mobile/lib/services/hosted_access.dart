import 'dart:convert';

import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_mobile/l10n/hosted_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

HostedLocalizations _hostedStrings() =>
    lookupHostedLocalizations(CloaklyLocale.current);

String get unconfirmedEmailMessage => _hostedStrings().emailNotConfirmed;

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
  final l10n = _hostedStrings();
  return switch (code) {
    'FREE_POOL_EXHAUSTED' => l10n.freePoolExhausted,
    'FREE_DAILY_LIMIT_REACHED' => l10n.freeDailyLimit,
    'FREE_QUESTION_LIMIT_REACHED' => l10n.freeQuestionLimit,
    'FREE_PLAN_LIMIT_REACHED' => l10n.freePlanLimit,
    'DEVICE_FREE_ACCOUNT_IN_USE' => l10n.deviceFreeAccountInUse,
    'DEVICE_REQUIRED' => l10n.deviceRequired,
    'EMAIL_NOT_CONFIRMED' => l10n.emailNotConfirmed,
    'MEETING_ALLOWANCE_REQUIRED' => l10n.meetingAllowanceRequired,
    'ALLOWANCE_RESERVATION_FAILED' => l10n.allowanceReservationFailed,
    'DUPLICATE_CLIENT_REQUEST' => l10n.duplicateClientRequest,
    'TRANSCRIPTION_NOT_CONFIGURED' => l10n.transcriptionNotConfigured,
    'TRANSCRIPTION_PROVIDER_FAILED' => l10n.transcriptionProviderFailed,
    'INTERNAL_ERROR' => l10n.serverError,
    _ =>
      code == null || code.isEmpty
          ? fallback
          : l10n.hostedFallback(fallback, code),
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
