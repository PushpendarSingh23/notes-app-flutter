const { v4: uuidv4 } = require('uuid');
const TaskRepository = require('../repositories/task.repository');
const NoteRepository = require('../repositories/note.repository');
const AppError = require('../utils/AppError');
const { pool, executeTransaction } = require('../config/database');

class TaskService {
  constructor() {
    this.taskRepo = new TaskRepository(pool);
    this.noteRepo = new NoteRepository(pool);
  }

  async getTasks(userId, queryParams) {
    return this.taskRepo.findByUser(userId, {
      status: queryParams.status,
      priority: queryParams.priority,
      dueBefore: queryParams.due_before,
      dueAfter: queryParams.due_after
    });
  }

  async getTaskById(id, userId) {
    const task = await this.taskRepo.findById(id, userId);
    if (!task) {
      throw new AppError('Task not found.', 404, 'TASK_NOT_FOUND');
    }
    task.subtasks = await this.taskRepo.getSubtasks(id);
    return task;
  }

  async createTask(userId, taskData) {
    return executeTransaction(async (connection) => {
      const repo = new TaskRepository(connection);
      const id = taskData.id || uuidv4();

      const task = await repo.create({ id, userId, ...taskData });

      if (Array.isArray(taskData.subtasks)) {
        let order = 0;
        for (const subtask of taskData.subtasks) {
          await repo.createSubtask({
            id: uuidv4(),
            taskId: id,
            title: subtask.title,
            isCompleted: !!subtask.isCompleted,
            sortOrder: order++
          });
        }
      }

      task.subtasks = await repo.getSubtasks(id);
      return task;
    });
  }

  async updateTask(id, userId, updateData) {
    try {
      return await executeTransaction(async (connection) => {
        const repo = new TaskRepository(connection);
        const updatedTask = await repo.update(id, userId, updateData, updateData.version);
        if (!updatedTask) {
          throw new AppError('Task not found.', 404, 'TASK_NOT_FOUND');
        }

        if (Array.isArray(updateData.subtasks)) {
          await repo.deleteSubtasksForTask(id);
          let order = 0;
          for (const subtask of updateData.subtasks) {
            await repo.createSubtask({
              id: subtask.id || uuidv4(),
              taskId: id,
              title: subtask.title,
              isCompleted: !!subtask.isCompleted,
              sortOrder: order++
            });
          }
        }

        updatedTask.subtasks = await repo.getSubtasks(id);
        return updatedTask;
      });
    } catch (error) {
      if (error.message === 'VERSION_CONFLICT') {
        const serverRecord = await this.taskRepo.findById(id, userId);
        throw new AppError(
          'Conflict detected. The task was modified on another device.',
          409,
          'CONCURRENCY_CONFLICT',
          { serverRecord }
        );
      }
      throw error;
    }
  }

  async deleteTask(id, userId) {
    const deleted = await this.taskRepo.softDelete(id, userId);
    if (!deleted) {
      throw new AppError('Task not found or already deleted.', 404, 'TASK_NOT_FOUND');
    }
    return true;
  }

  async updateStatus(id, userId, status) {
    const validStatuses = ['TODO', 'IN_PROGRESS', 'COMPLETED'];
    if (!validStatuses.includes(status)) {
      throw new AppError('Invalid task status provided.', 422, 'INVALID_STATUS');
    }
    const updated = await this.taskRepo.updateStatus(id, userId, status);
    if (!updated) {
      throw new AppError('Task not found.', 404, 'TASK_NOT_FOUND');
    }
    return this.getTaskById(id, userId);
  }

  async getDashboard(userId) {
    const taskStats = await this.taskRepo.getDashboardStats(userId);
    const totalNotes = await this.noteRepo.countByUser(userId, {});

    return {
      totalNotes,
      activeTasks: Number(taskStats.active_tasks) || 0,
      completedTasks: Number(taskStats.completed_tasks) || 0,
      overdueTasks: Number(taskStats.overdue_tasks) || 0,
      upcomingTasks: Number(taskStats.upcoming_tasks) || 0
    };
  }
}

module.exports = new TaskService();
