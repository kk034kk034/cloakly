import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguageChoice { system, zhHant, en }

const appLanguagePreferenceKey = 'cloakly.appLanguage';

/// Loaded before [runApp]. Missing or unknown values follow the device.
AppLanguageChoice bootAppLanguage = AppLanguageChoice.system;

AppLanguageChoice appLanguageFromStored(String? value) => switch (value) {
  'zh_Hant' => AppLanguageChoice.zhHant,
  'en' => AppLanguageChoice.en,
  _ => AppLanguageChoice.system,
};

String appLanguageStored(AppLanguageChoice choice) => switch (choice) {
  AppLanguageChoice.system => 'system',
  AppLanguageChoice.zhHant => 'zh_Hant',
  AppLanguageChoice.en => 'en',
};

/// Null lets [MaterialApp] follow the device. [resolveCloaklyLocale] still
/// maps any zh* locale to Traditional Chinese and every other locale to English.
Locale? localeOverrideFor(AppLanguageChoice choice) => switch (choice) {
  AppLanguageChoice.system => null,
  AppLanguageChoice.zhHant => cloaklyZhHant,
  AppLanguageChoice.en => cloaklyEn,
};

/// Effective locale for a saved choice plus the current device locale.
Locale resolveAppLanguage(AppLanguageChoice choice, Locale? device) {
  return resolveCloaklyLocale(
    localeOverrideFor(choice) ?? device,
    AppLocalizations.supportedLocales,
  );
}

Future<AppLanguageChoice> loadAppLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  return appLanguageFromStored(prefs.getString(appLanguagePreferenceKey));
}

class AppLanguageNotifier extends Notifier<AppLanguageChoice> {
  @override
  AppLanguageChoice build() => bootAppLanguage;

  Future<void> setChoice(AppLanguageChoice choice) async {
    if (state == choice) return;
    state = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appLanguagePreferenceKey, appLanguageStored(choice));
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguageChoice>(
      AppLanguageNotifier.new,
    );

class AppLocaleBuilder extends ConsumerWidget {
  const AppLocaleBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, Locale? locale) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(context, localeOverrideFor(ref.watch(appLanguageProvider)));
  }
}
