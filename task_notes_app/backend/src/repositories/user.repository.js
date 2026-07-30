const BaseRepository = require('./base.repository');

class UserRepository extends BaseRepository {
  constructor(db) {
    super('users', db);
  }

  async findByEmail(email) {
    const [rows] = await this.db.execute(
      'SELECT * FROM users WHERE email = ? AND deleted_at IS NULL',
      [email]
    );
    return rows[0] || null;
  }

  async create(userData) {
    const query = `
      INSERT INTO users (id, email, password_hash, first_name, last_name, role_id)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    await this.db.execute(query, [
      userData.id,
      userData.email,
      userData.passwordHash,
      userData.firstName,
      userData.lastName,
      userData.roleId || 1
    ]);
    return this.findById(userData.id);
  }

  async updateProfile(id, updateData) {
    const fields = [];
    const params = [];

    if (updateData.firstName !== undefined) { fields.push('first_name = ?'); params.push(updateData.firstName); }
    if (updateData.lastName !== undefined) { fields.push('last_name = ?'); params.push(updateData.lastName); }
    if (updateData.avatarUrl !== undefined) { fields.push('avatar_url = ?'); params.push(updateData.avatarUrl); }

    if (fields.length === 0) return this.findById(id);

    const query = `UPDATE users SET ${fields.join(', ')} WHERE id = ? AND deleted_at IS NULL`;
    params.push(id);
    await this.db.execute(query, params);
    return this.findById(id);
  }

  async saveRefreshToken(tokenData) {
    const query = `
      INSERT INTO refresh_tokens (id, user_id, token, expires_at)
      VALUES (?, ?, ?, ?)
    `;
    await this.db.execute(query, [
      tokenData.id,
      tokenData.userId,
      tokenData.token,
      tokenData.expiresAt
    ]);
  }

  async findRefreshToken(token) {
    const [rows] = await this.db.execute(
      'SELECT * FROM refresh_tokens WHERE token = ? AND is_revoked = 0 AND expires_at > NOW()',
      [token]
    );
    return rows[0] || null;
  }

  async revokeRefreshToken(token) {
    const [result] = await this.db.execute(
      'UPDATE refresh_tokens SET is_revoked = 1 WHERE token = ?',
      [token]
    );
    return result.affectedRows > 0;
  }
}

module.exports = UserRepository;
