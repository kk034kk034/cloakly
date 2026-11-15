import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/stt/mock_stt.dart';
import 'package:cloakly_core/services/stt/stt_engine.dart';
import 'package:cloakly_core/services/stt/soniox_stt.dart';

SttEngine createSttEngine(
  AppSettings settings, {
  SttLane lane = SttLane.self,
  int Function()? elapsedMs,
}) {
  if (settings.isDemo) return MockStt();
  if (!settings.hasLiveDiarize) {
    throw StateError(CloaklyLocale.strings.missingSonioxKey);
  }
  return SonioxStt(settings, lane: lane, elapsedMs: elapsedMs);
}
