import 'dart:convert';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/stt/soniox_stt.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_mobile/services/hosted_access.dart';
import 'package:cloakly_mobile/services/hosted_device.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SttEngineFactory createHostedSttEngineFactory(
  SupabaseClient supabase, {
  HostedSessionCoordinator? usage,
}) {
  final coordinator = usage ?? HostedSessionCoordinator(supabase);
  return (
    AppSettings settings, {
    required SttLane lane,
    int Function()? elapsedMs,
  }) {
    return SonioxStt(
      settings,
      lane: lane,
      elapsedMs: elapsedMs,
      apiKeyProvider: () => coordinator.temporaryKey(lane),
    );
  };
}

class HostedSessionCoordinator {
  HostedSessionCoordinator(this._supabase);

  final SupabaseClient _supabase;
  String? _sessionId;

  Future<String> temporaryKey(SttLane lane) async {
    FunctionException? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _fetchTemporaryKey(lane);
      } on FunctionException catch (error) {
        last = error;
        // Cold starts / stale reservation races often clear on a quick retry.
        if (attempt == 0 && (error.status == 500 || error.status == 502)) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
        }
        throw StateError(_messageFor(error));
      }
    }
    throw StateError(
      last == null ? '無法取得會議授權。' : _messageFor(last),
    );
  }

  Future<String> _fetchTemporaryKey(SttLane lane) async {
    final response = await _supabase.functions.invoke(
      'create-meeting-session',
      body: {
        'lane': lane.name,
        'deviceId': await HostedDeviceId.current(),
      },
    );
    final raw = response.data;
    final data = switch (raw) {
      Map<String, dynamic>() => raw,
      Map() => Map<String, dynamic>.from(raw),
      String() => Map<String, dynamic>.from(jsonDecode(raw) as Map),
      _ => throw StateError('無法解析會議授權'),
    };
    _sessionId = data['sessionId'] as String?;
    final key = data['temporaryApiKey'] as String?;
    if (key == null || key.trim().isEmpty) {
      throw StateError(data['error'] as String? ?? '後端沒有回傳 Soniox 短效金鑰');
    }
    return key.trim();
  }

  String _messageFor(FunctionException error) {
    return hostedQuotaMessage(
      error.details,
      fallback: switch (error.status) {
        404 => '手機版後端尚未部署 create-meeting-session。',
        401 => '登入已失效，請登出後重新登入。',
        403 => '這次免費額度無法使用。',
        502 => 'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。',
        503 => '後端尚未設定 Soniox API 金鑰。',
        _ => '無法取得會議授權（${error.status}）。',
      },
    );
  }

  Future<void> finish({required int durationSeconds}) async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      await _supabase.functions.invoke(
        'finish-meeting-session',
        body: {'sessionId': sessionId, 'durationSeconds': durationSeconds},
      );
    } finally {
      _sessionId = null;
    }
  }
}
