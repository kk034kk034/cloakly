import 'stt_engine.dart';

/// Reconciles immutable final tokens and replaceable speculative tokens.
/// Sentence boundaries never force the upstream audio session to reset.
class StreamingTranscript {
  StreamingTranscript({required this.lane, required this.sessionId});

  final SttLane lane;
  final String sessionId;
  final List<Map<String, dynamic>> _pending = [];
  final Map<String, int> _speakers = {};
  Set<String> _previewIds = {};
  int _sequence = 0;

  List<TranscriptEvent> accept(Map<String, dynamic> response) {
    final output = <TranscriptEvent>[];
    final speculative = <Map<String, dynamic>>[];
    final rawTokens = response['tokens'];
    for (final raw in rawTokens is List ? rawTokens : const []) {
      if (raw is! Map<String, dynamic> || raw['text'] is! String) continue;
      if (raw['translation_status'] == 'translation') continue;
      final text = raw['text'] as String;
      if (text.startsWith('<') && text.endsWith('>')) {
        if (raw['is_final'] == true && text == '<end>') _commit(output);
        continue;
      }
      if (raw['is_final'] != true) {
        speculative.add(raw);
        continue;
      }
      if (_pending.isNotEmpty && _boundary(_pending.last, raw)) {
        _commit(output);
      }
      _pending.add(raw);
      if (_endsSentence(text)) _commit(output);
    }
    if (response['finished'] == true ||
        (_pending.isNotEmpty &&
            (response['final_audio_proc_ms'] as num? ?? 0) -
                    (_pending.last['end_ms'] as num? ?? 0) >
                1000)) {
      _commit(output);
    }

    // Project the current draft without committing speaker guesses or IDs.
    final previews = <TranscriptEvent>[];
    var sequence = _sequence;
    var group = <Map<String, dynamic>>[];
    for (final token in [..._pending, ...speculative]) {
      if (group.isNotEmpty && _boundary(group.last, token)) {
        previews.add(_event(group, sequence++, false));
        group = [];
      }
      group.add(token);
      if (_endsSentence(token['text'] as String)) {
        previews.add(_event(group, sequence++, false));
        group = [];
      }
    }
    if (group.isNotEmpty) previews.add(_event(group, sequence, false));
    final currentIds = {
      ...output.map((e) => e.utteranceId!),
      ...previews.map((e) => e.utteranceId!),
    };
    for (final id in _previewIds.difference(currentIds)) {
      output.add(
        TranscriptEvent(
          text: '',
          isFinal: false,
          utteranceId: id,
          isRemoved: true,
        ),
      );
    }
    _previewIds = previews.map((e) => e.utteranceId!).toSet();
    return [...output, ...previews];
  }

  bool _boundary(Map<String, dynamic> a, Map<String, dynamic> b) =>
      a['speaker'] != b['speaker'] ||
      ((b['start_ms'] as num? ?? 0) - (a['end_ms'] as num? ?? 0) > 1000);

  bool _endsSentence(String text) =>
      RegExp(r'[。！？!?；;.][」』”"\s]*$').hasMatch(text);

  void _commit(List<TranscriptEvent> output) {
    if (_pending.isEmpty) return;
    final event = _event(_pending, _sequence++, true);
    if (event.text.trim().isNotEmpty) output.add(event);
    _pending.clear();
  }

  TranscriptEvent _event(
    List<Map<String, dynamic>> tokens,
    int sequence,
    bool finalText,
  ) {
    final rawSpeaker = tokens.first['speaker']?.toString();
    if (finalText && rawSpeaker != null && rawSpeaker.isNotEmpty) {
      _speakers.putIfAbsent(rawSpeaker, () => _speakers.length);
    }
    final index = _speakers[rawSpeaker];
    final known = lane == SttLane.self || index != null;
    return TranscriptEvent(
      utteranceId: '$sessionId:$sequence',
      text: tokens.map((t) => t['text'] as String).join().trim(),
      isFinal: finalText,
      speakerIndex: lane == SttLane.self
          ? 0
          : known
          ? SpeakerId.index(lane: lane, diarized: index!)
          : -1,
      speakerLabel: lane == SttLane.self
          ? '我'
          : known
          ? SpeakerId.label(lane: lane, diarized: index!)
          : '發言人待確認',
      speakerVerified: finalText && known,
      startMs: (tokens.first['start_ms'] as num?)?.round(),
      endMs: (tokens.last['end_ms'] as num?)?.round(),
    );
  }
}
