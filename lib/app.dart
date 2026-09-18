import 'package:cloakly/core/theme/app_theme.dart';
import 'package:cloakly/features/home/home_screen.dart';
import 'package:cloakly/features/meeting_detail/meeting_detail_screen.dart';
import 'package:cloakly/features/project/project_picker_screen.dart';
import 'package:cloakly/features/project/project_screen.dart';
import 'package:cloakly/features/session/session_screen.dart';
import 'package:cloakly/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
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
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class CloaklyApp extends StatelessWidget {
  const CloaklyApp({super.key});

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
      routerConfig: appRouter,
    );
  }
}
