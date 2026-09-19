import 'dart:convert';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostedAiService implements AiService {
  HostedAiService(this._supabase);

  final SupabaseClient _supabase;

  @override
  bool get isConfigured => _supabase.auth.currentSession != null;

  @override
  Future<String> suggestAnswer({
    required List<TranscriptLine> recent,
    required String trigger,
    String projectContext = '',
  }) async {
    final response = await _supabase.functions.invoke(
      'suggest-answer',
      body: {
        'recent': recent
            .map(
              (line) => {
                'speaker': line.speaker,
                'text': line.text,
                'startMs': line.startMs,
              },
            )
            .toList(),
        'trigger': trigger,
        'projectContext': projectContext,
      },
    );
    final data = _jsonMap(response.data);
    final answer = data['answer'] as String?;
    if (answer == null || answer.trim().isEmpty) {
      throw StateError('Hosted AI 沒有回傳回答建議');
    }
    return answer.trim();
  }

  @override
  Future<MinutesResult> generateMinutes({
    required Meeting meeting,
    required List<TranscriptLine> lines,
    required List<Note> notes,
    String projectContext = '',
  }) async {
    final response = await _supabase.functions.invoke(
      'generate-minutes',
      body: {
        'meeting': {
          'id': meeting.id,
          'title': meeting.title,
          'startedAt': meeting.startedAt.toIso8601String(),
        },
        'lines': lines
            .map(
              (line) => {
                'speaker': line.speaker,
                'text': line.text,
                'startMs': line.startMs,
              },
            )
            .toList(),
        'notes': notes.map((note) => {'text': note.text}).toList(),
        'projectContext': projectContext,
      },
    );
    final data = _jsonMap(response.data);
    return MinutesResult.parse(
      jsonEncode(data),
      fallbackTitle: meeting.title,
      lines: lines,
    );
  }

  Map<String, dynamic> _jsonMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw StateError('Hosted API 回傳格式無法解析');
  }
}
