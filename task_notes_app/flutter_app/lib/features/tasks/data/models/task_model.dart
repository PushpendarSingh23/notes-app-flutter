import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';

class SubtaskModel extends Subtask {
  const SubtaskModel({
    required super.id,
    required super.taskId,
    required super.title,
    required super.isCompleted,
    required super.sortOrder,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      isCompleted: _asBool(json['is_completed']),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  factory SubtaskModel.fromSqlite(Map<String, dynamic> row) {
    return SubtaskModel(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      title: row['title'] as String,
      isCompleted: (row['is_completed'] as int) == 1,
      sortOrder: row['sort_order'] as int? ?? 0,
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.status,
    required super.priority,
    super.dueDate,
    super.reminderTime,
    required super.version,
    required super.updatedAt,
    super.subtasks,
    super.syncStatus,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: taskStatusFromString(json['status'] as String? ?? 'TODO'),
      priority: taskPriorityFromString(json['priority'] as String? ?? 'MEDIUM'),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      reminderTime: json['reminder_time'] != null ? DateTime.parse(json['reminder_time']) : null,
      version: json['version'] as int? ?? 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subtasks: ((json['subtasks'] as List<dynamic>?) ?? [])
          .map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  factory TaskModel.fromSqlite(Map<String, dynamic> row, {List<SubtaskModel> subtasks = const []}) {
    return TaskModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      status: taskStatusFromString(row['status'] as String? ?? 'TODO'),
      priority: taskPriorityFromString(row['priority'] as String? ?? 'MEDIUM'),
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date']) : null,
      reminderTime: row['reminder_time'] != null ? DateTime.parse(row['reminder_time']) : null,
      version: row['version'] as int? ?? 1,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      subtasks: subtasks,
      syncStatus: row['sync_status'] as String? ?? 'SYNCED',
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': taskStatusToString(status),
      'priority': taskPriorityToString(priority),
      'due_date': dueDate?.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'version': version,
      'created_at': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'title': title,
      'description': description,
      'status': taskStatusToString(status),
      'priority': taskPriorityToString(priority),
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'version': version,
      'subtasks': subtasks.map((s) => {'title': s.title, 'isCompleted': s.isCompleted}).toList(),
    };
  }
}
