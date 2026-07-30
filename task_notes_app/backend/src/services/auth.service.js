const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const UserRepository = require('../repositories/user.repository');
const AppError = require('../utils/AppError');
const { pool } = require('../config/database');

const SALT_ROUNDS = 12;

class AuthService {
  constructor() {
    this.userRepo = new UserRepository(pool);
  }

  _signAccessToken(user) {
    return jwt.sign(
      { sub: user.id, roleId: user.role_id },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: process.env.JWT_ACCESS_EXPIRATION || '15m' }
    );
  }

  _signRefreshToken(user) {
    return jwt.sign(
      { sub: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRATION || '7d' }
    );
  }

  _sanitizeUser(user) {
    return {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      avatarUrl: user.avatar_url,
      roleId: user.role_id
    };
  }

  async register({ email, password, firstName, lastName }) {
    const existing = await this.userRepo.findByEmail(email);
    if (existing) {
      throw new AppError('An account with this email already exists.', 409, 'EMAIL_ALREADY_EXISTS');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const user = await this.userRepo.create({
      id: uuidv4(),
      email,
      passwordHash,
      firstName,
      lastName,
      roleId: 1
    });

    return this._issueTokens(user);
  }

  async login({ email, password }) {
    const user = await this.userRepo.findByEmail(email);
    if (!user || !user.is_active) {
      throw new AppError('Invalid email or password.', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new AppError('Invalid email or password.', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    return this._issueTokens(user);
  }

  async _issueTokens(user) {
    const accessToken = this._signAccessToken(user);
    const refreshToken = this._signRefreshToken(user);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.userRepo.saveRefreshToken({
      id: uuidv4(),
      userId: user.id,
      token: refreshToken,
      expiresAt
    });

    return {
      user: this._sanitizeUser(user),
      accessToken,
      refreshToken
    };
  }

  async refreshToken(token) {
    if (!token) {
      throw new AppError('Refresh token is required.', 400, 'REFRESH_TOKEN_MISSING');
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    } catch (error) {
      throw new AppError('Refresh token is invalid or expired.', 401, 'AUTH_REFRESH_TOKEN_INVALID');
    }

    const storedToken = await this.userRepo.findRefreshToken(token);
    if (!storedToken) {
      throw new AppError('Refresh token has been revoked or does not exist.', 401, 'AUTH_REFRESH_TOKEN_REVOKED');
    }

    const user = await this.userRepo.findById(decoded.sub);
    if (!user || !user.is_active) {
      throw new AppError('User account is no longer active.', 401, 'AUTH_USER_INVALID');
    }

    // Rotate refresh token: revoke old, issue new
    await this.userRepo.revokeRefreshToken(token);
    return this._issueTokens(user);
  }

  async logout(token) {
    if (!token) return true;
    return this.userRepo.revokeRefreshToken(token);
  }

  async getProfile(userId) {
    const user = await this.userRepo.findById(userId);
    if (!user) {
      throw new AppError('User not found.', 404, 'USER_NOT_FOUND');
    }
    return this._sanitizeUser(user);
  }

  async updateProfile(userId, updateData) {
    const user = await this.userRepo.updateProfile(userId, updateData);
    if (!user) {
      throw new AppError('User not found.', 404, 'USER_NOT_FOUND');
    }
    return this._sanitizeUser(user);
  }
}

module.exports = new AuthService();
