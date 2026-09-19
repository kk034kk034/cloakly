import 'package:cloakly_core/core/constants.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _prefix = 'cloakly.';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      sonioxApiKey: prefs.getString('${_prefix}sonioxApiKey') ?? '',
      transcriptionTerms: prefs.getString('${_prefix}transcriptionTerms') ?? '',
      openaiApiKey:
          prefs.getString('${_prefix}openaiApiKey') ?? defaults.openaiApiKey,
      chatModel: prefs.getString('${_prefix}chatModel') ?? defaults.chatModel,
      language: prefs.getString('${_prefix}language') ?? defaults.language,
      personalContext:
          prefs.getString('${_prefix}personalContext') ??
          defaults.personalContext,
      autoTrigger: AutoTrigger.values.byName(
        prefs.getString('${_prefix}autoTrigger') ?? defaults.autoTrigger.name,
      ),
      pace: Pace.values.byName(
        prefs.getString('${_prefix}pace') ?? defaults.pace.name,
      ),
      captureSystemAudio:
          prefs.getBool('${_prefix}captureSystemAudio') ??
          defaults.captureSystemAudio,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}openaiApiKey', settings.openaiApiKey);
    await prefs.setString('${_prefix}sonioxApiKey', settings.sonioxApiKey);
    await prefs.setString(
      '${_prefix}transcriptionTerms',
      settings.transcriptionTerms,
    );
    await prefs.setString('${_prefix}chatModel', settings.chatModel);
    await prefs.remove('${_prefix}openaiBaseUrl');
    await prefs.remove('${_prefix}whisperModel');
    await prefs.remove('${_prefix}deepgramApiKey');
    await prefs.setString('${_prefix}language', settings.language);
    await prefs.setString(
      '${_prefix}personalContext',
      settings.personalContext,
    );
    await prefs.setString('${_prefix}autoTrigger', settings.autoTrigger.name);
    await prefs.setString('${_prefix}pace', settings.pace.name);
    await prefs.remove('${_prefix}listenMode');
    await prefs.setBool(
      '${_prefix}captureSystemAudio',
      settings.captureSystemAudio,
    );
  }
}
