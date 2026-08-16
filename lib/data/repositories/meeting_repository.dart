import 'package:cloakly/data/db/app_database.dart';
import 'package:cloakly/data/models/models.dart';
import 'package:sqflite/sqflite.dart';

class MeetingRepository {
  MeetingRepository(this._db);

  final AppDatabase _db;

  Future<List<Meeting>> list() async {
    final rows = await _db.db.query(
      'meetings',
      orderBy: 'started_at DESC',
    );
    return rows.map(Meeting.fromMap).toList();
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
    final db = _db.db;
    await db.delete('transcript_lines', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('notes', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('suggestions', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
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

  Future<void> replaceLines(String meetingId, List<TranscriptLine> lines) async {
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
