import 'package:cloakly/core/constants.dart';

enum MeetingStatus { recording, paused, completed }

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.status,
    this.endedAt,
    this.minutesMarkdown,
    this.audioPath,
    this.projectId,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final MeetingStatus status;
  final String? minutesMarkdown;
  final String? audioPath;
  final String? projectId;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Meeting copyWith({
    String? title,
    DateTime? endedAt,
    MeetingStatus? status,
    String? minutesMarkdown,
    String? audioPath,
  }) {
    return Meeting(
      id: id,
      title: title ?? this.title,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      minutesMarkdown: minutesMarkdown ?? this.minutesMarkdown,
      audioPath: audioPath ?? this.audioPath,
      projectId: projectId,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'started_at': startedAt.millisecondsSinceEpoch,
    'ended_at': endedAt?.millisecondsSinceEpoch,
    'status': status.name,
    'minutes_markdown': minutesMarkdown,
    'audio_path': audioPath,
    'listen_mode': 'meeting',
    'project_id': projectId,
  };

  factory Meeting.fromMap(Map<String, Object?> map) {
    final rawProjectId = map['project_id'] as String?;
    return Meeting(
      id: map['id']! as String,
      title: map['title']! as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at']! as int),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['ended_at']! as int),
      status: MeetingStatus.values.byName(map['status']! as String),
      minutesMarkdown: map['minutes_markdown'] as String?,
      audioPath: map['audio_path'] as String?,
      projectId: rawProjectId == null || rawProjectId.isEmpty
          ? null
          : rawProjectId,
    );
  }
}

class TranscriptLine {
  const TranscriptLine({
    required this.id,
    required this.meetingId,
    required this.speaker,
    required this.speakerIndex,
    required this.text,
    required this.isFinal,
    required this.startMs,
    required this.endMs,
  });

  final String id;
  final String meetingId;
  final String speaker;
  final int speakerIndex;
  final String text;
  final bool isFinal;
  final int startMs;
  final int endMs;

  TranscriptLine copyWith({
    String? speaker,
    int? speakerIndex,
    String? text,
    bool? isFinal,
    int? endMs,
  }) {
    return TranscriptLine(
      id: id,
      meetingId: meetingId,
      speaker: speaker ?? this.speaker,
      speakerIndex: speakerIndex ?? this.speakerIndex,
      text: text ?? this.text,
      isFinal: isFinal ?? this.isFinal,
      startMs: startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'meeting_id': meetingId,
    'speaker': speaker,
    'speaker_index': speakerIndex,
    'text': text,
    'is_final': isFinal ? 1 : 0,
    'start_ms': startMs,
    'end_ms': endMs,
  };

  factory TranscriptLine.fromMap(Map<String, Object?> map) {
    return TranscriptLine(
      id: map['id']! as String,
      meetingId: map['meeting_id']! as String,
      speaker: map['speaker']! as String,
      speakerIndex: map['speaker_index']! as int,
      text: map['text']! as String,
      isFinal: (map['is_final']! as int) == 1,
      startMs: map['start_ms']! as int,
      endMs: map['end_ms']! as int,
    );
  }
}

class Note {
  const Note({
    required this.id,
    required this.meetingId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String meetingId;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'meeting_id': meetingId,
    'text': text,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id']! as String,
      meetingId: map['meeting_id']! as String,
      text: map['text']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }
}

class Suggestion {
  const Suggestion({
    required this.id,
    required this.meetingId,
    required this.triggerText,
    required this.answer,
    required this.createdAt,
  });

  final String id;
  final String meetingId;
  final String triggerText;
  final String answer;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'meeting_id': meetingId,
    'trigger_text': triggerText,
    'answer': answer,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Suggestion.fromMap(Map<String, Object?> map) {
    return Suggestion(
      id: map['id']! as String,
      meetingId: map['meeting_id']! as String,
      triggerText: map['trigger_text']! as String,
      answer: map['answer']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.openaiApiKey,
    required this.chatModel,
    required this.language,
    required this.personalContext,
    required this.autoTrigger,
    required this.pace,
    this.captureSystemAudio = true,
    this.sonioxApiKey = '',
    this.transcriptionTerms = '',
  });

  final String openaiApiKey;
  final String chatModel;
  final String language;
  final String personalContext;
  final AutoTrigger autoTrigger;
  final Pace pace;
  final bool captureSystemAudio;
  final String sonioxApiKey;
  final String transcriptionTerms;

  bool get hasLlm => openaiApiKey.trim().isNotEmpty;
  bool get hasLiveDiarize => sonioxApiKey.trim().isNotEmpty;
  bool get isDemo => !hasLlm && !hasLiveDiarize;

  factory AppSettings.defaults() => const AppSettings(
    openaiApiKey: '',
    chatModel: 'gpt-4o-mini',
    language: 'zh',
    personalContext: '',
    autoTrigger: AutoTrigger.questions,
    pace: Pace.balanced,
    captureSystemAudio: true,
  );

  AppSettings copyWith({
    String? openaiApiKey,
    String? chatModel,
    String? language,
    String? personalContext,
    AutoTrigger? autoTrigger,
    Pace? pace,
    bool? captureSystemAudio,
    String? sonioxApiKey,
    String? transcriptionTerms,
  }) {
    return AppSettings(
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      chatModel: chatModel ?? this.chatModel,
      language: language ?? this.language,
      personalContext: personalContext ?? this.personalContext,
      autoTrigger: autoTrigger ?? this.autoTrigger,
      pace: pace ?? this.pace,
      captureSystemAudio: captureSystemAudio ?? this.captureSystemAudio,
      sonioxApiKey: sonioxApiKey ?? this.sonioxApiKey,
      transcriptionTerms: transcriptionTerms ?? this.transcriptionTerms,
    );
  }
}

class MeetingBundle {
  const MeetingBundle({
    required this.meeting,
    required this.lines,
    required this.notes,
    required this.suggestions,
  });

  final Meeting meeting;
  final List<TranscriptLine> lines;
  final List<Note> notes;
  final List<Suggestion> suggestions;
}
