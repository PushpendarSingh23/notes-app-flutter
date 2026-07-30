import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blueGrey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  TaskStatus _nextStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.completed;
      case TaskStatus.completed:
        return TaskStatus.todo;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
        child: tasksState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (tasks) {
            if (tasks.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.checklist_outlined, size: 64, color: Colors.grey)),
                  SizedBox(height: 16),
                  Center(child: Text('No tasks yet. Tap + to add one!')),
                ],
              );
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => ref.read(tasksProvider.notifier).updateStatus(task.id, _nextStatus(task.status)),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null) Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: task.progress),
                        if (task.isOverdue)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _priorityColor(task.priority),
                      child: Icon(
                        task.status == TaskStatus.completed
                            ? Icons.check
                            : task.status == TaskStatus.inProgress
                                ? Icons.hourglass_bottom
                                : Icons.radio_button_unchecked,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(tasksProvider.notifier).deleteTask(task.id),
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
          ref.read(tasksProvider.notifier).addTask(
                'New Task',
                description: 'Created offline',
                dueDate: DateTime.now().add(const Duration(days: 2)),
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
