import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/core/theme/theme_controller.dart';
import 'package:cloakly_core/l10n/app_language.dart';
import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/features/home/home_screen.dart';
import 'package:cloakly_core/features/home/meetings_list_screen.dart';
import 'package:cloakly_core/features/meeting_detail/meeting_detail_screen.dart';
import 'package:cloakly_core/features/project/project_picker_screen.dart';
import 'package:cloakly_core/features/project/project_plan_screen.dart';
import 'package:cloakly_core/features/project/project_screen.dart';
import 'package:cloakly_core/features/project/project_question_screen.dart';
import 'package:cloakly_core/features/session/session_screen.dart';
import 'package:cloakly_core/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter({
  WidgetBuilder? settingsBuilder,
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectPickerScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'project/:id/questions',
          builder: (context, state) =>
              ProjectQuestionScreen(projectId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'project/:id/plan',
          builder: (context, state) =>
              ProjectPlanScreen(projectId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'session',
          builder: (context, state) => const SessionScreen(),
        ),
        GoRoute(
          path: 'meetings',
          builder: (context, state) => const MeetingsListScreen(),
        ),
        GoRoute(
          path: 'meeting/:id',
          builder: (context, state) =>
              MeetingDetailScreen(meetingId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'project',
          builder: (context, state) => const ProjectScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          settingsBuilder?.call(context) ?? const SettingsScreen(),
    ),
  ],
);

class CloaklyApp extends ConsumerStatefulWidget {
  const CloaklyApp({
    super.key,
    this.settingsBuilder,
    this.localizationsDelegates = const [],
  });

  final WidgetBuilder? settingsBuilder;
  final List<LocalizationsDelegate<dynamic>> localizationsDelegates;

  @override
  ConsumerState<CloaklyApp> createState() => _CloaklyAppState();
}

class _CloaklyAppState extends ConsumerState<CloaklyApp> {
  late final GoRouter _router = createAppRouter(
    settingsBuilder: widget.settingsBuilder,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cloakly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: localeOverrideFor(ref.watch(appLanguageProvider)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        ...widget.localizationsDelegates,
        ...AppLocalizations.localizationsDelegates,
      ],
      localeResolutionCallback: resolveCloaklyLocale,
      builder: cloaklyLocaleBuilder,
      routerConfig: _router,
    );
  }
}
