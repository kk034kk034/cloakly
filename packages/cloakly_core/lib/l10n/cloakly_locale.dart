import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

const cloaklyEn = Locale('en');

const cloaklyZhHant = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);

/// zh* (any Chinese language, script, or region) uses Traditional Chinese.
/// Every other locale uses English.
///
/// Pass the device locale to follow the system. Pass [cloaklyZhHant] or
/// [cloaklyEn] when an in-app choice overrides the device.
Locale resolveCloaklyLocale(Locale? locale, Iterable<Locale> supported) {
  if (locale != null && locale.languageCode.toLowerCase() == 'zh') {
    for (final item in supported) {
      if (item.languageCode == 'zh' && item.scriptCode == 'Hant') return item;
    }
    for (final item in supported) {
      if (item.languageCode == 'zh') return item;
    }
    return cloaklyZhHant;
  }
  for (final item in supported) {
    if (item.languageCode == 'en') return item;
  }
  return cloaklyEn;
}

/// Locale used by code that has no [BuildContext]. Widgets should prefer
/// [CloaklyContextL10n.l10n]. The app binds this from the resolved locale.
class CloaklyLocale {
  static Locale? _override;

  static Locale get current {
    if (_override != null) return _override!;
    try {
      return resolveCloaklyLocale(
        WidgetsBinding.instance.platformDispatcher.locale,
        AppLocalizations.supportedLocales,
      );
    } catch (_) {
      return cloaklyEn;
    }
  }

  static void bind(Locale locale) {
    _override = resolveCloaklyLocale(locale, AppLocalizations.supportedLocales);
  }

  static void reset() => _override = null;

  static AppLocalizations get strings => lookupAppLocalizations(current);
}

Widget cloaklyLocaleBuilder(BuildContext context, Widget? child) {
  CloaklyLocale.bind(Localizations.localeOf(context));
  return child ?? const SizedBox.shrink();
}

extension CloaklyContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
