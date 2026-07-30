const authService = require('../services/auth.service');
const { sendResponse } = require('../utils/responseHandler');

const register = async (req, res, next) => {
  try {
    const result = await authService.register(req.body);
    return sendResponse(res, 201, 'User registered successfully', result);
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.login(req.body);
    return sendResponse(res, 200, 'Login successful', result);
  } catch (error) {
    next(error);
  }
};

const refresh = async (req, res, next) => {
  try {
    const result = await authService.refreshToken(req.body.refreshToken);
    return sendResponse(res, 200, 'Token refreshed successfully', result);
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    await authService.logout(req.body.refreshToken);
    return sendResponse(res, 200, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const profile = await authService.getProfile(req.user.id);
    return sendResponse(res, 200, 'Profile retrieved successfully', profile);
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const profile = await authService.updateProfile(req.user.id, req.body);
    return sendResponse(res, 200, 'Profile updated successfully', profile);
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login, refresh, logout, getProfile, updateProfile };
