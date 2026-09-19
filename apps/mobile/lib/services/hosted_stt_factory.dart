import 'dart:convert';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/stt/soniox_stt.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/state/providers.dart';
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
    late final FunctionResponse response;
    try {
      response = await _supabase.functions.invoke(
        'create-meeting-session',
        body: {'lane': lane.name},
      );
    } on FunctionException catch (error) {
      throw StateError(switch (error.status) {
        404 => '手機版後端尚未部署 create-meeting-session。',
        401 => '登入已失效，請登出後重新登入。',
        429 => '今天的免費會議額度已使用完畢。',
        502 => 'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。',
        503 => '後端尚未設定 Soniox API 金鑰。',
        _ => '無法取得會議授權（${error.status}）。',
      });
    }
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
