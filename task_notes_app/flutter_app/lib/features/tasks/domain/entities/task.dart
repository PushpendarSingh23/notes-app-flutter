import 'subtask.dart';

enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { low, medium, high, urgent }

TaskStatus taskStatusFromString(String value) {
  switch (value) {
    case 'IN_PROGRESS':
      return TaskStatus.inProgress;
    case 'COMPLETED':
      return TaskStatus.completed;
    case 'TODO':
    default:
      return TaskStatus.todo;
  }
}

String taskStatusToString(TaskStatus status) {
  switch (status) {
    case TaskStatus.inProgress:
      return 'IN_PROGRESS';
    case TaskStatus.completed:
      return 'COMPLETED';
    case TaskStatus.todo:
      return 'TODO';
  }
}

TaskPriority taskPriorityFromString(String value) {
  switch (value) {
    case 'LOW':
      return TaskPriority.low;
    case 'HIGH':
      return TaskPriority.high;
    case 'URGENT':
      return TaskPriority.urgent;
    case 'MEDIUM':
    default:
      return TaskPriority.medium;
  }
}

String taskPriorityToString(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return 'LOW';
    case TaskPriority.high:
      return 'HIGH';
    case TaskPriority.urgent:
      return 'URGENT';
    case TaskPriority.medium:
      return 'MEDIUM';
  }
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final int version;
  final DateTime updatedAt;
  final List<Subtask> subtasks;
  final String syncStatus;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.reminderTime,
    required this.version,
    required this.updatedAt,
    this.subtasks = const [],
    this.syncStatus = 'SYNCED',
  });

  double get progress {
    if (subtasks.isEmpty) return status == TaskStatus.completed ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  bool get isOverdue =>
      dueDate != null && status != TaskStatus.completed && dueDate!.isBefore(DateTime.now());
}
