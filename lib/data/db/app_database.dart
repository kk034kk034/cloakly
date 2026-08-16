import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static Future<AppDatabase> open() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(dir.path, 'cloakly'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final path = p.join(dbDir.path, 'cloakly.db');

    final database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meetings (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              started_at INTEGER NOT NULL,
              ended_at INTEGER,
              status TEXT NOT NULL,
              minutes_markdown TEXT,
              audio_path TEXT,
              listen_mode TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE transcript_lines (
              id TEXT PRIMARY KEY,
              meeting_id TEXT NOT NULL,
              speaker TEXT NOT NULL,
              speaker_index INTEGER NOT NULL,
              text TEXT NOT NULL,
              is_final INTEGER NOT NULL,
              start_ms INTEGER NOT NULL,
              end_ms INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE notes (
              id TEXT PRIMARY KEY,
              meeting_id TEXT NOT NULL,
              text TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE suggestions (
              id TEXT PRIMARY KEY,
              meeting_id TEXT NOT NULL,
              trigger_text TEXT NOT NULL,
              answer TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );

    return AppDatabase(database);
  }
}
