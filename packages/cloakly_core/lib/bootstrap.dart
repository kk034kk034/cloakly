import 'package:cloakly_core/app.dart';
import 'package:cloakly_core/data/db/app_database.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
import 'package:cloakly_core/data/repositories/project_repository.dart';
import 'package:cloakly_core/data/repositories/settings_repository.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> runCloaklyApp({
  AiServiceFactory? aiServiceFactory,
  SttEngineFactory? sttEngineFactory,
  SessionUsageReporter? sessionUsageReporter,
  bool hostedMode = false,
  WidgetBuilder? settingsBuilder,
  Widget Function(Widget child)? appShellBuilder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  bootSettings = await SettingsRepository().load();
  final migrated = await ProjectRepository().loadLibrary();
  if (migrated.migratedProjectId != null) {
    await MeetingRepository(
      database,
    ).assignUnassignedTo(migrated.migratedProjectId!);
  }
  final app = CloaklyApp(settingsBuilder: settingsBuilder);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        hostedModeProvider.overrideWithValue(hostedMode),
        if (aiServiceFactory != null)
          aiServiceFactoryProvider.overrideWithValue(aiServiceFactory),
        if (sttEngineFactory != null)
          sttEngineFactoryProvider.overrideWithValue(sttEngineFactory),
        if (sessionUsageReporter != null)
          sessionUsageReporterProvider.overrideWithValue(sessionUsageReporter),
      ],
      child: appShellBuilder?.call(app) ?? app,
    ),
  );
}
