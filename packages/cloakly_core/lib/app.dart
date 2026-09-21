import 'package:cloakly_core/core/theme/app_theme.dart';
import 'package:cloakly_core/features/home/home_screen.dart';
import 'package:cloakly_core/features/meeting_detail/meeting_detail_screen.dart';
import 'package:cloakly_core/features/project/project_picker_screen.dart';
import 'package:cloakly_core/features/project/project_plan_screen.dart';
import 'package:cloakly_core/features/project/project_screen.dart';
import 'package:cloakly_core/features/project/project_question_screen.dart';
import 'package:cloakly_core/features/session/session_screen.dart';
import 'package:cloakly_core/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter({WidgetBuilder? settingsBuilder}) => GoRouter(
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

class CloaklyApp extends StatefulWidget {
  const CloaklyApp({super.key, this.settingsBuilder});

  final WidgetBuilder? settingsBuilder;

  @override
  State<CloaklyApp> createState() => _CloaklyAppState();
}

class _CloaklyAppState extends State<CloaklyApp> {
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
      theme: AppTheme.dark(),
      locale: const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
