const BaseRepository = require('./base.repository');

class TaskRepository extends BaseRepository {
  constructor(db) {
    super('tasks', db);
  }

  async create(taskData) {
    const query = `
      INSERT INTO tasks (id, user_id, category_id, title, description, status, priority, due_date, reminder_time, version)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      taskData.id,
      taskData.userId,
      taskData.categoryId || null,
      taskData.title,
      taskData.description || null,
      taskData.status || 'TODO',
      taskData.priority || 'MEDIUM',
      taskData.dueDate || null,
      taskData.reminderTime || null,
      taskData.version || 1
    ];
    await this.db.execute(query, params);
    return this.findById(taskData.id, taskData.userId);
  }

  async update(id, userId, updateData, expectedVersion) {
    const fields = [];
    const params = [];

    if (updateData.title !== undefined) { fields.push('title = ?'); params.push(updateData.title); }
    if (updateData.description !== undefined) { fields.push('description = ?'); params.push(updateData.description); }
    if (updateData.status !== undefined) { fields.push('status = ?'); params.push(updateData.status); }
    if (updateData.priority !== undefined) { fields.push('priority = ?'); params.push(updateData.priority); }
    if (updateData.dueDate !== undefined) { fields.push('due_date = ?'); params.push(updateData.dueDate); }
    if (updateData.reminderTime !== undefined) { fields.push('reminder_time = ?'); params.push(updateData.reminderTime); }
    if (updateData.categoryId !== undefined) { fields.push('category_id = ?'); params.push(updateData.categoryId); }

    if (fields.length === 0) return this.findById(id, userId);

    fields.push('version = version + 1');

    let query = `UPDATE tasks SET ${fields.join(', ')} WHERE id = ? AND user_id = ? AND deleted_at IS NULL`;
    params.push(id, userId);

    if (expectedVersion !== undefined && expectedVersion !== null) {
      query += ' AND version = ?';
      params.push(expectedVersion);
    }

    const [result] = await this.db.execute(query, params);
    if (result.affectedRows === 0 && expectedVersion !== undefined && expectedVersion !== null) {
      const existing = await this.findById(id, userId);
      if (!existing) return null;
      throw new Error('VERSION_CONFLICT');
    }

    return this.findById(id, userId);
  }

  async createSubtask(subtaskData) {
    const query = `
      INSERT INTO task_subtasks (id, task_id, title, is_completed, sort_order)
      VALUES (?, ?, ?, ?, ?)
    `;
    await this.db.execute(query, [
      subtaskData.id,
      subtaskData.taskId,
      subtaskData.title,
      subtaskData.isCompleted ? 1 : 0,
      subtaskData.sortOrder || 0
    ]);
  }

  async deleteSubtasksForTask(taskId) {
    await this.db.execute('DELETE FROM task_subtasks WHERE task_id = ?', [taskId]);
  }

  async getSubtasks(taskId) {
    const [rows] = await this.db.execute(
      'SELECT * FROM task_subtasks WHERE task_id = ? ORDER BY sort_order ASC, created_at ASC',
      [taskId]
    );
    return rows;
  }

  async updateStatus(id, userId, status) {
    const query = `
      UPDATE tasks SET status = ?, version = version + 1
      WHERE id = ? AND user_id = ? AND deleted_at IS NULL
    `;
    const [result] = await this.db.execute(query, [status, id, userId]);
    return result.affectedRows > 0;
  }

  async findByUser(userId, options = {}) {
    let query = 'SELECT * FROM tasks WHERE user_id = ? AND deleted_at IS NULL';
    const params = [userId];

    if (options.status) {
      query += ' AND status = ?';
      params.push(options.status);
    }
    if (options.priority) {
      query += ' AND priority = ?';
      params.push(options.priority);
    }
    if (options.dueBefore) {
      query += ' AND due_date <= ?';
      params.push(options.dueBefore);
    }
    if (options.dueAfter) {
      query += ' AND due_date >= ?';
      params.push(options.dueAfter);
    }

    query += ' ORDER BY due_date ASC, priority DESC';

    const [rows] = await this.db.execute(query, params);

    for (const task of rows) {
      task.subtasks = await this.getSubtasks(task.id);
    }

    return rows;
  }

  async getDashboardStats(userId) {
    const [[totals]] = await this.db.query(
      `SELECT
        SUM(CASE WHEN status != 'COMPLETED' THEN 1 ELSE 0 END) AS active_tasks,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_tasks,
        SUM(CASE WHEN status != 'COMPLETED' AND due_date IS NOT NULL AND due_date < NOW() THEN 1 ELSE 0 END) AS overdue_tasks,
        SUM(CASE WHEN status != 'COMPLETED' AND due_date IS NOT NULL AND due_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS upcoming_tasks
       FROM tasks WHERE user_id = ? AND deleted_at IS NULL`,
      [userId]
    );
    return totals;
  }
}

module.exports = TaskRepository;
