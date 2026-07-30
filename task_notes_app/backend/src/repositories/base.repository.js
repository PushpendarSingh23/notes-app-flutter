class BaseRepository {
  constructor(tableName, poolOrConnection) {
    this.tableName = tableName;
    this.db = poolOrConnection;
  }

  async findById(id, userId = null) {
    let query = `SELECT * FROM ${this.tableName} WHERE id = ? AND deleted_at IS NULL`;
    const params = [id];
    if (userId) {
      query += ' AND user_id = ?';
      params.push(userId);
    }
    const [rows] = await this.db.execute(query, params);
    return rows[0] || null;
  }

  async softDelete(id, userId = null) {
    let query = `UPDATE ${this.tableName} SET deleted_at = NOW() WHERE id = ? AND deleted_at IS NULL`;
    const params = [id];
    if (userId) {
      query += ' AND user_id = ?';
      params.push(userId);
    }
    const [result] = await this.db.execute(query, params);
    return result.affectedRows > 0;
  }
}

module.exports = BaseRepository;
