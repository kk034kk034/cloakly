import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_mobile/l10n/hosted_localizations.dart';
import 'package:flutter/material.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({this.theme, this.locale, super.key});

  final ThemeData? theme;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? AppTheme.dark();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: resolved,
      darkTheme: resolved,
      localizationsDelegates: const [
        HostedLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveCloaklyLocale,
      builder: cloaklyLocaleBuilder,
      home: const _ConfigurationErrorPage(),
    );
  }
}

class _ConfigurationErrorPage extends StatelessWidget {
  const _ConfigurationErrorPage();

  @override
  Widget build(BuildContext context) {
    final l10n = HostedLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.settings_suggest_outlined, size: 52),
                  SizedBox(height: 20),
                  Text(
                    l10n.hostedNotConfigured,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  SelectableText(l10n.hostedConfigHelp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.message,
    this.theme,
    this.locale,
    super.key,
  });

  final String message;
  final ThemeData? theme;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? AppTheme.dark();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: resolved,
      darkTheme: resolved,
      locale: locale,
      localizationsDelegates: const [
        HostedLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveCloaklyLocale,
      builder: cloaklyLocaleBuilder,
      home: _StartupErrorPage(message: message),
    );
  }
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = HostedLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 20),
                  Text(
                    l10n.startupFailed,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(message),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
