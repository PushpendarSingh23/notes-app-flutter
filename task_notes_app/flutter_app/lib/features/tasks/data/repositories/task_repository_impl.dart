import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/local/sqlite_service.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final SQLiteService _sqliteService;
  final String Function() currentUserId;

  TaskRepositoryImpl(this._sqliteService, {required this.currentUserId});

  Future<List<SubtaskModel>> _getSubtasks(DatabaseExecutor db, String taskId) async {
    final rows = await db.query(
      'task_subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => SubtaskModel.fromSqlite(r)).toList();
  }

  Future<void> _enqueueMutation(
    DatabaseExecutor db, {
    required String entityId,
    required String httpMethod,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    await db.insert('sync_queue', {
      'entity_id': entityId,
      'entity_type': 'TASK',
      'http_method': httpMethod,
      'endpoint': endpoint,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'PENDING',
    });
  }

  @override
  Future<Either<Failure, List<Task>>> getTasks() async {
    try {
      final db = await _sqliteService.database;
      final rows = await db.query(
        'tasks',
        where: 'deleted_at IS NULL',
        orderBy: 'due_date ASC',
      );
      final tasks = <TaskModel>[];
      for (final row in rows) {
        final subtasks = await _getSubtasks(db, row['id'] as String);
        tasks.add(TaskModel.fromSqlite(row, subtasks: subtasks));
      }
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch local tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> subtaskTitles = const [],
  }) async {
    try {
      final db = await _sqliteService.database;
      final taskId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      final subtasks = <SubtaskModel>[];
      var order = 0;
      for (final t in subtaskTitles) {
        subtasks.add(SubtaskModel(
          id: const Uuid().v4(),
          taskId: taskId,
          title: t,
          isCompleted: false,
          sortOrder: order++,
        ));
      }

      final newTask = TaskModel(
        id: taskId,
        userId: currentUserId(),
        title: title,
        description: description,
        status: TaskStatus.todo,
        priority: priority,
        dueDate: dueDate,
        version: 1,
        updatedAt: now,
        subtasks: subtasks,
        syncStatus: 'PENDING_CREATE',
      );

      await db.transaction((txn) async {
        await txn.insert('tasks', newTask.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
        for (final s in subtasks) {
          await txn.insert('task_subtasks', s.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await _enqueueMutation(
          txn,
          entityId: taskId,
          httpMethod: 'POST',
          endpoint: '/tasks',
          payload: newTask.toApiPayload(),
        );
      });

      return Right(newTask);
    } catch (e) {
      return Left(DatabaseFailure('Failed to create task locally: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> updateStatus(String id, TaskStatus status) async {
    try {
      final db = await _sqliteService.database;
      final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) {
        return const Left(DatabaseFailure('Task not found locally.'));
      }
      final subtasks = await _getSubtasks(db, id);
      final existing = TaskModel.fromSqlite(rows.first, subtasks: subtasks);

      final updated = TaskModel(
        id: existing.id,
        userId: existing.userId,
        title: existing.title,
        description: existing.description,
        status: status,
        priority: existing.priority,
        dueDate: existing.dueDate,
        reminderTime: existing.reminderTime,
        version: existing.version,
        updatedAt: DateTime.now().toUtc(),
        subtasks: existing.subtasks,
        syncStatus: 'PENDING_UPDATE',
      );

      await db.update('tasks', updated.toSqlite(), where: 'id = ?', whereArgs: [id]);
      await _enqueueMutation(
        db,
        entityId: id,
        httpMethod: 'PUT',
        endpoint: '/tasks',
        payload: updated.toApiPayload(),
      );

      return Right(updated);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update task status locally: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      final db = await _sqliteService.database;
      await db.update(
        'tasks',
        {'deleted_at': DateTime.now().toUtc().toIso8601String(), 'sync_status': 'PENDING_DELETE'},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _enqueueMutation(
        db,
        entityId: id,
        httpMethod: 'DELETE',
        endpoint: '/tasks',
        payload: {},
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete task locally: $e'));
    }
  }
}
