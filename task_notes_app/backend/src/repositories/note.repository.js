const BaseRepository = require('./base.repository');

class NoteRepository extends BaseRepository {
  constructor(db) {
    super('notes', db);
  }

  async create(noteData) {
    const query = `
      INSERT INTO notes (id, user_id, category_id, title, content, is_pinned, is_archived, is_favorite, color_hex, version)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      noteData.id,
      noteData.userId,
      noteData.categoryId || null,
      noteData.title,
      noteData.content || null,
      noteData.isPinned ? 1 : 0,
      noteData.isArchived ? 1 : 0,
      noteData.isFavorite ? 1 : 0,
      noteData.colorHex || '#FFFFFF',
      noteData.version || 1
    ];
    await this.db.execute(query, params);
    return this.findById(noteData.id, noteData.userId);
  }

  async updateWithVersionCheck(id, userId, updateData, expectedVersion) {
    const fields = [];
    const params = [];

    if (updateData.title !== undefined) { fields.push('title = ?'); params.push(updateData.title); }
    if (updateData.content !== undefined) { fields.push('content = ?'); params.push(updateData.content); }
    if (updateData.categoryId !== undefined) { fields.push('category_id = ?'); params.push(updateData.categoryId); }
    if (updateData.isPinned !== undefined) { fields.push('is_pinned = ?'); params.push(updateData.isPinned ? 1 : 0); }
    if (updateData.isArchived !== undefined) { fields.push('is_archived = ?'); params.push(updateData.isArchived ? 1 : 0); }
    if (updateData.isFavorite !== undefined) { fields.push('is_favorite = ?'); params.push(updateData.isFavorite ? 1 : 0); }
    if (updateData.colorHex !== undefined) { fields.push('color_hex = ?'); params.push(updateData.colorHex); }

    if (fields.length === 0) return this.findById(id, userId);

    fields.push('version = version + 1');

    const query = `
      UPDATE notes SET ${fields.join(', ')}
      WHERE id = ? AND user_id = ? AND version = ? AND deleted_at IS NULL
    `;
    params.push(id, userId, expectedVersion);

    const [result] = await this.db.execute(query, params);
    if (result.affectedRows === 0) {
      const existing = await this.findById(id, userId);
      if (!existing) return null;
      throw new Error('VERSION_CONFLICT');
    }

    return this.findById(id, userId);
  }

  async setArchived(id, userId, isArchived) {
    const query = `
      UPDATE notes SET is_archived = ?, version = version + 1
      WHERE id = ? AND user_id = ? AND deleted_at IS NULL
    `;
    const [result] = await this.db.execute(query, [isArchived ? 1 : 0, id, userId]);
    return result.affectedRows > 0;
  }

  async setPinned(id, userId, isPinned) {
    const query = `
      UPDATE notes SET is_pinned = ?, version = version + 1
      WHERE id = ? AND user_id = ? AND deleted_at IS NULL
    `;
    const [result] = await this.db.execute(query, [isPinned ? 1 : 0, id, userId]);
    return result.affectedRows > 0;
  }

  async findByUser(userId, options = {}) {
    let query = 'SELECT * FROM notes WHERE user_id = ? AND deleted_at IS NULL';
    const params = [userId];

    if (options.isArchived !== undefined) {
      query += ' AND is_archived = ?';
      params.push(options.isArchived ? 1 : 0);
    }
    if (options.categoryId) {
      query += ' AND category_id = ?';
      params.push(options.categoryId);
    }
    if (options.search) {
      query += ' AND (title LIKE ? OR content LIKE ?)';
      const searchTerm = `%${options.search}%`;
      params.push(searchTerm, searchTerm);
    }

    query += ' ORDER BY is_pinned DESC, updated_at DESC';

    if (options.limit && options.offset !== undefined) {
      query += ' LIMIT ? OFFSET ?';
      params.push(parseInt(options.limit, 10), parseInt(options.offset, 10));
    }

    const [rows] = await this.db.execute(query, params);
    return rows;
  }

  async countByUser(userId, options = {}) {
    let query = 'SELECT COUNT(*) as total FROM notes WHERE user_id = ? AND deleted_at IS NULL';
    const params = [userId];
    if (options.isArchived !== undefined) {
      query += ' AND is_archived = ?';
      params.push(options.isArchived ? 1 : 0);
    }
    const [rows] = await this.db.execute(query, params);
    return rows[0].total;
  }
}

module.exports = NoteRepository;
