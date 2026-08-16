enum SttLane {
  /// Headset mic in an online call: always you.
  self,

  /// System / loopback audio: other people on the call, diarized.
  remote,

  /// In-person, everyone on one microphone, diarized.
  room,
}

class SpeakerId {
  static String letter(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index >= 0 && index < letters.length) {
      return letters[index];
    }
    return '${index + 1}';
  }

  static int index({required SttLane lane, int diarized = 0}) {
    return switch (lane) {
      SttLane.self => 0,
      SttLane.remote => 1 + diarized,
      SttLane.room => diarized,
    };
  }

  static String label({required SttLane lane, int diarized = 0}) {
    return switch (lane) {
      SttLane.self => '我',
      SttLane.remote => '對方${letter(diarized)}',
      SttLane.room => '發言人 ${diarized + 1}',
    };
  }
}

class TranscriptEvent {
  const TranscriptEvent({
    required this.text,
    required this.isFinal,
    this.speakerIndex = 0,
    this.speakerLabel,
  });

  final String text;
  final bool isFinal;
  final int speakerIndex;
  final String? speakerLabel;
}

abstract class SttEngine {
  Stream<TranscriptEvent> get events;
  Future<void> start();
  void addAudio(List<int> pcm);
  Future<void> flush();
  Future<void> stop();
}

String speakerLabelFor(int index) {
  if (index <= 0) return SpeakerId.label(lane: SttLane.self);
  return SpeakerId.label(lane: SttLane.remote, diarized: index - 1);
}
