import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks();
  Future<Either<Failure, Task>> createTask({
    required String title,
    String? description,
    TaskPriority priority,
    DateTime? dueDate,
    List<String> subtaskTitles,
  });
  Future<Either<Failure, Task>> updateStatus(String id, TaskStatus status);
  Future<Either<Failure, void>> deleteTask(String id);
}
