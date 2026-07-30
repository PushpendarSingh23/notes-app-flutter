const taskService = require('../services/task.service');
const { sendResponse } = require('../utils/responseHandler');

const getDashboard = async (req, res, next) => {
  try {
    const stats = await taskService.getDashboard(req.user.id);
    return sendResponse(res, 200, 'Dashboard statistics retrieved successfully', stats);
  } catch (error) {
    next(error);
  }
};

module.exports = { getDashboard };
