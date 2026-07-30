import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';
import '../models/note_model.dart';

/// Offline-first note repository. Every read comes from SQLite (the single
/// source of truth for the presentation layer); every write is applied to
/// SQLite immediately (optimistic UI) and queued for background sync.
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  final String Function() currentUserId;

  NoteRepositoryImpl(this.localDataSource, {required this.currentUserId});

  @override
  Future<Either<Failure, List<Note>>> getNotes() async {
    try {
      final notes = await localDataSource.getNotes();
      return Right(notes);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> createNote(String title, String content) async {
    try {
      final note = await localDataSource.createNote(currentUserId(), title, content);
      return Right(note);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> updateNote(Note note) async {
    try {
      final model = NoteModel(
        id: note.id,
        userId: note.userId,
        title: note.title,
        content: note.content,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isFavorite: note.isFavorite,
        colorHex: note.colorHex,
        version: note.version,
        updatedAt: note.updatedAt,
      );
      final updated = await localDataSource.updateNote(model);
      return Right(updated);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await localDataSource.deleteNote(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> togglePin(String id, bool isPinned) async {
    try {
      final notes = await localDataSource.getNotes();
      final existing = notes.firstWhere((n) => n.id == id);
      final updated = await localDataSource.updateNote(
        NoteModel(
          id: existing.id,
          userId: existing.userId,
          title: existing.title,
          content: existing.content,
          isPinned: isPinned,
          isArchived: existing.isArchived,
          isFavorite: existing.isFavorite,
          colorHex: existing.colorHex,
          version: existing.version,
          updatedAt: existing.updatedAt,
        ),
      );
      return Right(updated);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Note>> toggleArchive(String id, bool isArchived) async {
    try {
      final notes = await localDataSource.getNotes();
      final existing = notes.firstWhere((n) => n.id == id);
      final updated = await localDataSource.updateNote(
        NoteModel(
          id: existing.id,
          userId: existing.userId,
          title: existing.title,
          content: existing.content,
          isPinned: existing.isPinned,
          isArchived: isArchived,
          isFavorite: existing.isFavorite,
          colorHex: existing.colorHex,
          version: existing.version,
          updatedAt: existing.updatedAt,
        ),
      );
      return Right(updated);
    } on CacheException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
