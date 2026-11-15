import 'package:cloakly_core/app.dart';
import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/settings/settings_screen.dart';
import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Projects extends ProjectsNotifier {
  @override
  Future<ProjectLibrary> build() async => ProjectLibrary(
    activeId: 'p1',
    projects: [
      ProjectPack(
        id: 'p1',
        folderPath: '/project',
        name: 'alpha',
        indexedAt: DateTime(2026),
        docs: const [],
      ),
    ],
  );
}

class _Meetings extends MeetingsNotifier {
  @override
  Future<List<Meeting>> build() async => [
    Meeting(
      id: 'm1',
      title: 'Weekly',
      startedAt: DateTime(2026, 9, 1),
      status: MeetingStatus.completed,
    ),
  ];
}

void main() {
  setUp(() => CloaklyLocale.bind(cloaklyEn));
  tearDown(() => CloaklyLocale.bind(cloaklyZhHant));

  testWidgets('english locale renders English on the home screen', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith(_Projects.new),
          meetingsProvider.overrideWith(_Meetings.new),
          demoModeProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(),
          locale: cloaklyEn,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: resolveCloaklyLocale,
          builder: cloaklyLocaleBuilder,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start meeting'), findsOneWidget);
    expect(find.text('Project Q&A'), findsOneWidget);
    expect(find.text('Project status'), findsOneWidget);
    expect(find.text('Meetings'), findsOneWidget);
    expect(find.text('開始會議'), findsNothing);
    expect(find.textContaining('1 meeting'), findsOneWidget);
    expect(find.textContaining('For example: which meeting'), findsOneWidget);
  });

  testWidgets('english locale renders English settings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: cloaklyEn,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: resolveCloaklyLocale,
          builder: cloaklyLocaleBuilder,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Soniox API key'), findsOneWidget);
    expect(find.text('外觀'), findsNothing);
  });
}
