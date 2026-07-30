import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notes/presentation/providers/note_provider.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final stats = ref.watch(taskDashboardStatsProvider);
    final totalNotes = notesState.maybeWhen(data: (notes) => notes.length, orElse: () => 0);

    final cards = [
      _StatCardData('Total Notes', totalNotes, Icons.note_alt_outlined, Colors.purple),
      _StatCardData('Active Tasks', stats['active'] ?? 0, Icons.pending_actions, Colors.blue),
      _StatCardData('Completed', stats['completed'] ?? 0, Icons.check_circle_outline, Colors.green),
      _StatCardData('Overdue', stats['overdue'] ?? 0, Icons.warning_amber_outlined, Colors.red),
      _StatCardData('Upcoming (7d)', stats['upcoming'] ?? 0, Icons.upcoming_outlined, Colors.orange),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notesProvider.notifier).loadNotes();
          await ref.read(tasksProvider.notifier).loadTasks();
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(card.icon, color: card.color, size: 28),
                    Text(
                      '${card.value}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(card.label, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _StatCardData(this.label, this.value, this.icon, this.color);
}
