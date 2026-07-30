import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_provider.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
        child: notesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (notes) {
            if (notes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey)),
                  SizedBox(height: 16),
                  Center(child: Text('No notes yet. Tap + to create one!')),
                ],
              );
            }
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Color(int.parse(note.colorHex.replaceFirst('#', '0xFF'))),
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      note.content ?? 'No content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: IconButton(
                      icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                      onPressed: () => ref.read(notesProvider.notifier).togglePin(note.id, !note.isPinned),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.syncStatus == 'SYNCED' ? Icons.cloud_done : Icons.cloud_queue,
                          color: note.syncStatus == 'SYNCED' ? Colors.green : Colors.orange,
                        ),
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => ref.read(notesProvider.notifier).toggleArchive(note.id, !note.isArchived),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(notesProvider.notifier).deleteNote(note.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(notesProvider.notifier).addNote('New Note', 'Created offline at ${DateTime.now()}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
