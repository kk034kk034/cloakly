import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

class MeetingFunctionResult {
  const MeetingFunctionResult({required this.status, this.data, this.details});

  final int status;
  final Object? data;
  final Object? details;

  bool get ok => status >= 200 && status < 300;
}

typedef MeetingFunctionInvoker =
    Future<MeetingFunctionResult> Function(
      String name, {
      required Map<String, dynamic> body,
    });

class _RetryableAuthorization implements Exception {
  _RetryableAuthorization(this.message);

  final String message;
}

class _AuthorizationTicket {
  _AuthorizationTicket(this.generation, this.clientRequestId);

  final int generation;
  final String clientRequestId;
  bool abandoned = false;
}

class HostedSessionCoordinator {
  HostedSessionCoordinator(
    SupabaseClient? supabase, {
    MeetingFunctionInvoker? invoke,
    Future<String> Function()? deviceId,
    this.fetchTimeout = const Duration(seconds: 8),
    this.finishTimeout = const Duration(seconds: 8),
    this.retryDelay = const Duration(milliseconds: 600),
    Random? random,
  }) : _invoke = invoke ?? _supabaseInvoke(supabase),
       _deviceId = deviceId ?? HostedDeviceId.current,
       _random = random ?? Random.secure();

  final MeetingFunctionInvoker _invoke;
  final Future<String> Function() _deviceId;
  final Duration fetchTimeout;
  final Duration finishTimeout;
  final Duration retryDelay;
  final Random _random;
  final List<String> _sessionIds = [];
  int _generation = 0;

  static MeetingFunctionInvoker _supabaseInvoke(SupabaseClient? supabase) {
    final client = supabase;
    if (client == null) {
      throw ArgumentError('HostedSessionCoordinator 需要 Supabase 或測試用 invoker');
    }
    return (name, {required body}) async {
      try {
        final response = await client.functions.invoke(name, body: body);
        return MeetingFunctionResult(
          status: response.status,
          data: response.data,
        );
      } on FunctionException catch (error) {
        return MeetingFunctionResult(
          status: error.status,
          details: error.details,
        );
      }
    };
  }

  void abandonPendingAuthorization() {
    _generation++;
  }

  Future<String> temporaryKey(SttLane lane) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final generation = _generation;
      final ticket = _AuthorizationTicket(generation, _newRequestId());
      try {
        return await _fetchTemporaryKey(lane, ticket).timeout(
          fetchTimeout,
          onTimeout: () {
            ticket.abandoned = true;
            throw TimeoutException('取得會議授權逾時');
          },
        );
      } on TimeoutException {
        // Do not retry: the server may already have activated this reservation.
        unawaited(_releaseUnknown(ticket.clientRequestId));
        throw StateError('取得會議授權逾時，請再試一次。');
      } on _RetryableAuthorization catch (error) {
        if (attempt == 1 || generation != _generation || ticket.abandoned) {
          throw StateError(error.message);
        }
        await Future<void>.delayed(retryDelay);
        if (generation != _generation) throw StateError('已取消會議授權');
      }
    }
    throw StateError('無法取得會議授權。');
  }

  Future<String> _fetchTemporaryKey(
    SttLane lane,
    _AuthorizationTicket ticket,
  ) async {
    final result = await _invoke(
      'create-meeting-session',
      body: {
        'lane': lane.name,
        'deviceId': await _deviceId(),
        'clientRequestId': ticket.clientRequestId,
      },
    );
    if (ticket.abandoned || ticket.generation != _generation) {
      if (result.ok) {
        final late = _jsonMap(result.data);
        final sessionId = late['sessionId'] as String?;
        if (sessionId != null && sessionId.isNotEmpty) {
          unawaited(_finish(sessionId: sessionId, durationSeconds: 0));
        }
      }
      unawaited(_releaseUnknown(ticket.clientRequestId));
      throw StateError('取得會議授權逾時，請再試一次。');
    }
    if (!result.ok) {
      final message = _messageFor(result.status, result.details);
      if (result.status == 500 || result.status == 502) {
        throw _RetryableAuthorization(message);
      }
      throw StateError(message);
    }
    final data = _jsonMap(result.data);
    final sessionId = data['sessionId'] as String?;
    final key = data['temporaryApiKey'] as String?;
    if (ticket.abandoned || ticket.generation != _generation) {
      if (sessionId != null && sessionId.isNotEmpty) {
        unawaited(_finish(sessionId: sessionId, durationSeconds: 0));
      } else {
        unawaited(_releaseUnknown(ticket.clientRequestId));
      }
      throw StateError('取得會議授權逾時，請再試一次。');
    }
    if (sessionId != null &&
        sessionId.isNotEmpty &&
        !_sessionIds.contains(sessionId)) {
      _sessionIds.add(sessionId);
    }
    if (key == null || key.trim().isEmpty) {
      throw StateError(data['error'] as String? ?? '後端沒有回傳 Soniox 短效金鑰');
    }
    return key.trim();
  }

  String _messageFor(int status, Object? details) {
    return hostedQuotaMessage(
      details,
      fallback: switch (status) {
        404 => '手機版後端尚未部署 create-meeting-session。',
        401 => '登入已失效，請登出後重新登入。',
        403 => '這次免費額度無法使用。',
        502 => 'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。',
        503 => '後端尚未設定 Soniox API 金鑰。',
        _ => '無法取得會議授權（$status）。',
      },
    );
  }

  Future<void> finish({required int durationSeconds}) async {
    final ids = List<String>.of(_sessionIds);
    _sessionIds.clear();
    for (final sessionId in ids) {
      try {
        await _finish(
          sessionId: sessionId,
          durationSeconds: durationSeconds,
        ).timeout(finishTimeout);
      } catch (_) {}
    }
  }

  Future<void> _releaseUnknown(String clientRequestId) async {
    try {
      await _finish(
        clientRequestId: clientRequestId,
        durationSeconds: 0,
      ).timeout(finishTimeout);
    } catch (_) {}
    // The row may not be visible until the server finishes reserving.
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 700), () async {
        try {
          await _finish(
            clientRequestId: clientRequestId,
            durationSeconds: 0,
          ).timeout(finishTimeout);
        } catch (_) {}
      }),
    );
  }

  Future<void> _finish({
    String? sessionId,
    String? clientRequestId,
    required int durationSeconds,
  }) async {
    await _invoke(
      'finish-meeting-session',
      body: {
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        if (clientRequestId != null && clientRequestId.isNotEmpty)
          'clientRequestId': clientRequestId,
        'durationSeconds': durationSeconds,
      },
    );
  }

  Map<String, dynamic> _jsonMap(Object? raw) {
    return switch (raw) {
      Map<String, dynamic>() => raw,
      Map() => Map<String, dynamic>.from(raw),
      String() => Map<String, dynamic>.from(jsonDecode(raw) as Map),
      _ => throw StateError('無法解析會議授權'),
    };
  }

  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final text = bytes.map(hex).join();
    return '${text.substring(0, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}-${text.substring(16, 20)}-${text.substring(20)}';
  }
}
