import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/sqlite_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/note_local_datasource.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

final noteLocalDataSourceProvider = Provider<NoteLocalDataSource>((ref) {
  return NoteLocalDataSourceImpl(SQLiteService());
});

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(
    ref.watch(noteLocalDataSourceProvider),
    currentUserId: () => ref.read(authProvider).valueOrNull?.id ?? 'anonymous',
  );
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository _repository;

  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    final result = await _repository.getNotes();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (notes) => state = AsyncValue.data(notes),
    );
  }

  Future<void> addNote(String title, String content) async {
    final result = await _repository.createNote(title, content);
    result.fold(
      (failure) => null, // Surfaced via UI Snackbar by the screen listening to this call
      (newNote) {
        state.whenData((currentNotes) {
          state = AsyncValue.data([newNote, ...currentNotes]);
        });
      },
    );
  }

  Future<void> togglePin(String id, bool isPinned) async {
    final result = await _repository.togglePin(id, isPinned);
    result.fold(
      (failure) => null,
      (updated) {
        state.whenData((currentNotes) {
          state = AsyncValue.data([
            for (final n in currentNotes)
              if (n.id == id) updated else n
          ]);
        });
      },
    );
  }

  Future<void> toggleArchive(String id, bool isArchived) async {
    final result = await _repository.toggleArchive(id, isArchived);
    result.fold(
      (failure) => null,
      (updated) {
        state.whenData((currentNotes) {
          state = AsyncValue.data([
            for (final n in currentNotes)
              if (n.id == id) updated else n
          ]);
        });
      },
    );
  }

  Future<void> deleteNote(String id) async {
    final previousState = state;
    state.whenData((currentNotes) {
      state = AsyncValue.data(currentNotes.where((n) => n.id != id).toList());
    });
    final result = await _repository.deleteNote(id);
    result.fold(
      (failure) => state = previousState, // roll back optimistic removal on failure
      (_) => null,
    );
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier(ref.watch(noteRepositoryProvider));
});
