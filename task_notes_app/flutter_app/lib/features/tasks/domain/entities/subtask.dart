class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.sortOrder,
  });

  Subtask copyWith({bool? isCompleted}) {
    return Subtask(
      id: id,
      taskId: taskId,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder,
    );
  }
}
