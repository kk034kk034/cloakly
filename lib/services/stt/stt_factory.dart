import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/stt/mock_stt.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:cloakly/services/stt/whisper_stt.dart';

SttEngine createSttEngine(
  AppSettings settings, {
  SttLane lane = SttLane.self,
}) {
  if (settings.hasLlm) {
    return WhisperStt(settings, lane: lane);
  }
  return MockStt();
}
