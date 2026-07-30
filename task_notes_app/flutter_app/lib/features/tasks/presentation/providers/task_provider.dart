import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/sqlite_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    SQLiteService(),
    currentUserId: () => ref.read(authProvider).valueOrNull?.id ?? 'anonymous',
  );
});

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    final result = await _repository.getTasks();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (tasks) => state = AsyncValue.data(tasks),
    );
  }

  Future<void> addTask(String title, {String? description, TaskPriority priority = TaskPriority.medium, DateTime? dueDate}) async {
    final result = await _repository.createTask(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    result.fold(
      (failure) => null,
      (newTask) {
        state.whenData((current) => state = AsyncValue.data([newTask, ...current]));
      },
    );
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final result = await _repository.updateStatus(id, status);
    result.fold(
      (failure) => null,
      (updated) {
        state.whenData((current) {
          state = AsyncValue.data([for (final t in current) if (t.id == id) updated else t]);
        });
      },
    );
  }

  Future<void> deleteTask(String id) async {
    final previous = state;
    state.whenData((current) => state = AsyncValue.data(current.where((t) => t.id != id).toList()));
    final result = await _repository.deleteTask(id);
    result.fold((failure) => state = previous, (_) => null);
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>((ref) {
  return TasksNotifier(ref.watch(taskRepositoryProvider));
});

/// Derived counts used by the dashboard screen.
final taskDashboardStatsProvider = Provider<Map<String, int>>((ref) {
  final tasksState = ref.watch(tasksProvider);
  return tasksState.maybeWhen(
    data: (tasks) => {
      'active': tasks.where((t) => t.status != TaskStatus.completed).length,
      'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
      'upcoming': tasks
          .where((t) =>
              t.dueDate != null &&
              t.status != TaskStatus.completed &&
              t.dueDate!.isAfter(DateTime.now()) &&
              t.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7))))
          .length,
    },
    orElse: () => {'active': 0, 'completed': 0, 'overdue': 0, 'upcoming': 0},
  );
});
