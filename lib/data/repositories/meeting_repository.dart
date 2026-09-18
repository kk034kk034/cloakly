import 'dart:io';

import 'package:cloakly/data/db/app_database.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final _uuidPrefix = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

class MeetingRepository {
  MeetingRepository(this._db);

  final AppDatabase _db;

  Future<List<Meeting>> list({
    String? projectId,
    bool unassignedOnly = false,
  }) async {
    final List<Map<String, Object?>> rows;
    if (unassignedOnly) {
      rows = await _db.db.query(
        'meetings',
        where: 'project_id IS NULL OR project_id = ?',
        whereArgs: [''],
        orderBy: 'started_at DESC',
      );
    } else if (projectId != null) {
      rows = await _db.db.query(
        'meetings',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'started_at DESC',
      );
    } else {
      rows = await _db.db.query('meetings', orderBy: 'started_at DESC');
    }
    return rows.map(Meeting.fromMap).toList();
  }

  Future<int> countUnassigned() async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS c FROM meetings WHERE project_id IS NULL OR project_id = ?',
      [''],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> assignUnassignedTo(String projectId) async {
    await _db.db.update(
      'meetings',
      {'project_id': projectId},
      where: 'project_id IS NULL OR project_id = ?',
      whereArgs: [''],
    );
  }

  Future<void> unassignProject(String projectId) async {
    await _db.db.update(
      'meetings',
      {'project_id': null},
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> deleteByProject(String projectId) async {
    final meetings = await list(projectId: projectId);
    for (final meeting in meetings) {
      await deleteMeeting(meeting.id);
    }
    return meetings.length;
  }

  Future<Meeting?> getById(String id) async {
    final rows = await _db.db.query(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Meeting.fromMap(rows.first);
  }

  Future<MeetingBundle> loadBundle(String id) async {
    final meeting = await getById(id);
    if (meeting == null) {
      throw StateError('找不到會議 $id');
    }
    final lines = await listLines(id);
    final notes = await listNotes(id);
    final suggestions = await listSuggestions(id);
    return MeetingBundle(
      meeting: meeting,
      lines: lines,
      notes: notes,
      suggestions: suggestions,
    );
  }

  Future<void> upsertMeeting(Meeting meeting) async {
    await _db.db.insert(
      'meetings',
      meeting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMeeting(String id) async {
    final meeting = await getById(id);
    final db = _db.db;
    await db.delete(
      'transcript_lines',
      where: 'meeting_id = ?',
      whereArgs: [id],
    );
    await db.delete('notes', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('suggestions', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
    await _deleteInternalAudioFiles(id, meeting?.audioPath);
    await purgeOrphanAudio();
  }

  Future<void> purgeOrphanAudio() async {
    final keep = {for (final meeting in await list()) meeting.id};
    final roots = [await _audioRoot()];
    for (final root in roots) {
      if (!await root.exists()) continue;
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        final id = _meetingIdFromAudioName(name);
        if (id == null || keep.contains(id)) continue;
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _deleteInternalAudioFiles(String id, String? audioPath) async {
    final dir = audioPath == null || audioPath.isEmpty
        ? await audioDirFor(null)
        : Directory(p.dirname(audioPath));
    final paths = <String>{
      if (audioPath != null && audioPath.isNotEmpty) audioPath,
      p.join(dir.path, '$id.m4a'),
      p.join(dir.path, '$id.wav'),
      p.join(dir.path, '$id-mic.tmp.wav'),
      p.join(dir.path, '$id-system.tmp.wav'),
    };
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<Directory> audioDirFor(String? projectId) async {
    final dir = projectId == null || projectId.isEmpty
        ? await _audioRoot()
        : Directory(p.join((await _audioRoot()).path, projectId));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _storageRoot() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'cloakly'));
  }

  Future<Directory> _audioRoot() async {
    return Directory(p.join((await _storageRoot()).path, 'recordings'));
  }

  String? _meetingIdFromAudioName(String name) {
    final match = _uuidPrefix.firstMatch(name);
    if (match == null || match.start != 0) return null;
    final rest = name.substring(match.end);
    if (rest == '.wav' ||
        rest == '.m4a' ||
        (rest.startsWith('-') &&
            (rest.endsWith('.wav') || rest.endsWith('.m4a')))) {
      return match.group(0);
    }
    return null;
  }

  Future<List<TranscriptLine>> listLines(String meetingId) async {
    final rows = await _db.db.query(
      'transcript_lines',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
      orderBy: 'start_ms ASC',
    );
    return rows.map(TranscriptLine.fromMap).toList();
  }

  Future<void> upsertLine(TranscriptLine line) async {
    await _db.db.insert(
      'transcript_lines',
      line.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceLines(
    String meetingId,
    List<TranscriptLine> lines,
  ) async {
    final db = _db.db;
    await db.delete(
      'transcript_lines',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
    );
    final batch = db.batch();
    for (final line in lines) {
      batch.insert('transcript_lines', line.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Note>> listNotes(String meetingId) async {
    final rows = await _db.db.query(
      'notes',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> addNote(Note note) async {
    await _db.db.insert('notes', note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _db.db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Suggestion>> listSuggestions(String meetingId) async {
    final rows = await _db.db.query(
      'suggestions',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Suggestion.fromMap).toList();
  }

  Future<void> addSuggestion(Suggestion suggestion) async {
    await _db.db.insert('suggestions', suggestion.toMap());
  }
}
