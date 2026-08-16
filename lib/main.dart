import 'package:cloakly/app.dart';
import 'package:cloakly/data/db/app_database.dart';
import 'package:cloakly/data/repositories/settings_repository.dart';
import 'package:cloakly/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  bootSettings = await SettingsRepository().load();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const CloaklyApp(),
    ),
  );
}
