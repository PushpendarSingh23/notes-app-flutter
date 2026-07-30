const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');
const { pool } = require('../config/database');

const authenticate = async (req, res, next) => {
  try {
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      throw new AppError('Authentication required. Please provide a valid bearer token.', 401, 'AUTH_TOKEN_MISSING');
    }

    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

    const [users] = await pool.execute(
      'SELECT id, email, first_name, last_name, role_id, is_active FROM users WHERE id = ? AND deleted_at IS NULL',
      [decoded.sub]
    );

    if (users.length === 0 || !users[0].is_active) {
      throw new AppError('The user belonging to this token no longer exists or is inactive.', 401, 'AUTH_USER_INVALID');
    }

    req.user = {
      id: users[0].id,
      email: users[0].email,
      firstName: users[0].first_name,
      lastName: users[0].last_name,
      roleId: users[0].role_id
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new AppError('Invalid token signature.', 401, 'AUTH_TOKEN_INVALID'));
    }
    if (error.name === 'TokenExpiredError') {
      return next(new AppError('Access token has expired.', 401, 'AUTH_TOKEN_EXPIRED'));
    }
    next(error);
  }
};

// roleId: 1 = USER, 2 = ADMIN (see roles table)
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.roleId)) {
      return next(new AppError('You do not have permission to perform this action.', 403, 'AUTH_INSUFFICIENT_PERMISSIONS'));
    }
    next();
  };
};

module.exports = { authenticate, authorizeRoles };
