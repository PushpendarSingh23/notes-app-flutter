import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_notes_app/core/local/sqlite_service.dart';
import 'package:task_notes_app/features/notes/data/datasources/note_local_datasource.dart';
import 'package:task_notes_app/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  setUpAll(() {
    // Use the FFI sqflite implementation so tests can run on the host
    // (desktop/CI) instead of requiring an Android/iOS test device.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late NoteRepositoryImpl repository;

  setUp(() {
    final localDataSource = NoteLocalDataSourceImpl(SQLiteService());
    repository = NoteRepositoryImpl(localDataSource, currentUserId: () => 'test-user');
  });

  test('createNote persists a note locally with PENDING_CREATE sync status', () async {
    final result = await repository.createNote('Test title', 'Test content');

    result.fold(
      (failure) => fail('Expected a successful local write, got failure: ${failure.message}'),
      (note) {
        expect(note.title, 'Test title');
        expect(note.content, 'Test content');
        expect(note.syncStatus, 'PENDING_CREATE');
      },
    );
  });

  test('getNotes returns notes that were just created offline', () async {
    await repository.createNote('Offline note', 'Written with no connectivity');
    final result = await repository.getNotes();

    result.fold(
      (failure) => fail('Expected a successful read, got failure: ${failure.message}'),
      (notes) => expect(notes.any((n) => n.title == 'Offline note'), isTrue),
    );
  });
}
