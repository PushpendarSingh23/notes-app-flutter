import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/local/sqlite_service.dart';
import '../models/note_model.dart';

abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> createNote(String userId, String title, String content);
  Future<NoteModel> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<void> applyServerRecord(Map<String, dynamic> serverNote);
  Future<void> enqueueMutation({
    required String entityId,
    required String httpMethod,
    required String endpoint,
    required Map<String, dynamic> payload,
  });
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final SQLiteService sqliteService;

  NoteLocalDataSourceImpl(this.sqliteService);

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      final db = await sqliteService.database;
      final rows = await db.query(
        'notes',
        where: 'deleted_at IS NULL',
        orderBy: 'is_pinned DESC, updated_at DESC',
      );
      return rows.map((r) => NoteModel.fromSqlite(r)).toList();
    } catch (e) {
      throw CacheException('Failed to read notes from local database: $e');
    }
  }

  @override
  Future<NoteModel> createNote(String userId, String title, String content) async {
    try {
      final db = await sqliteService.database;
      final newNote = NoteModel(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        content: content,
        isPinned: false,
        isArchived: false,
        isFavorite: false,
        colorHex: '#FFFFFF',
        version: 1,
        updatedAt: DateTime.now().toUtc(),
        syncStatus: 'PENDING_CREATE',
      );

      await db.transaction((txn) async {
        await txn.insert('notes', newNote.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
      });

      await enqueueMutation(
        entityId: newNote.id,
        httpMethod: 'POST',
        endpoint: '/notes',
        payload: {'id': newNote.id, 'title': title, 'content': content},
      );

      return newNote;
    } catch (e) {
      throw CacheException('Failed to create note locally: $e');
    }
  }

  @override
  Future<NoteModel> updateNote(NoteModel note) async {
    try {
      final db = await sqliteService.database;
      final updated = NoteModel(
        id: note.id,
        userId: note.userId,
        title: note.title,
        content: note.content,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isFavorite: note.isFavorite,
        colorHex: note.colorHex,
        version: note.version, // server increments version on successful sync
        updatedAt: DateTime.now().toUtc(),
        syncStatus: 'PENDING_UPDATE',
      );

      await db.update('notes', updated.toSqlite(), where: 'id = ?', whereArgs: [note.id]);

      await enqueueMutation(
        entityId: note.id,
        httpMethod: 'PUT',
        endpoint: '/notes',
        payload: note.toApiPayload(),
      );

      return updated;
    } catch (e) {
      throw CacheException('Failed to update note locally: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      final db = await sqliteService.database;
      await db.update(
        'notes',
        {'deleted_at': DateTime.now().toUtc().toIso8601String(), 'sync_status': 'PENDING_DELETE'},
        where: 'id = ?',
        whereArgs: [id],
      );

      await enqueueMutation(
        entityId: id,
        httpMethod: 'DELETE',
        endpoint: '/notes',
        payload: {},
      );
    } catch (e) {
      throw CacheException('Failed to delete note locally: $e');
    }
  }

  @override
  Future<void> applyServerRecord(Map<String, dynamic> serverNote) async {
    final db = await sqliteService.database;
    final model = NoteModel.fromJson(serverNote, syncStatus: 'SYNCED');
    await db.update('notes', model.toSqlite(), where: 'id = ?', whereArgs: [model.id]);
  }

  @override
  Future<void> enqueueMutation({
    required String entityId,
    required String httpMethod,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final db = await sqliteService.database;
    await db.insert('sync_queue', {
      'entity_id': entityId,
      'entity_type': 'NOTE',
      'http_method': httpMethod,
      'endpoint': endpoint,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'PENDING',
    });
  }
}
