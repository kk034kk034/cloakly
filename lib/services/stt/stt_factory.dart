import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/stt/mock_stt.dart';
import 'package:cloakly/services/stt/stt_engine.dart';
import 'package:cloakly/services/stt/soniox_stt.dart';

SttEngine createSttEngine(
  AppSettings settings, {
  SttLane lane = SttLane.self,
  int Function()? elapsedMs,
}) {
  if (settings.isDemo) return MockStt();
  if (!settings.hasLiveDiarize) {
    throw StateError('請在設定填入 Soniox API 金鑰以啟用多人串流逐字稿。OpenAI 金鑰用於回答建議與會議紀錄。');
  }
  return SonioxStt(settings, lane: lane, elapsedMs: elapsedMs);
}
