const taskService = require('../services/task.service');
const { sendResponse } = require('../utils/responseHandler');

const getTasks = async (req, res, next) => {
  try {
    const tasks = await taskService.getTasks(req.user.id, req.query);
    return sendResponse(res, 200, 'Tasks retrieved successfully', tasks);
  } catch (error) {
    next(error);
  }
};

const getTaskById = async (req, res, next) => {
  try {
    const task = await taskService.getTaskById(req.params.id, req.user.id);
    return sendResponse(res, 200, 'Task retrieved successfully', task);
  } catch (error) {
    next(error);
  }
};

const createTask = async (req, res, next) => {
  try {
    const task = await taskService.createTask(req.user.id, req.body);
    return sendResponse(res, 201, 'Task created successfully', task);
  } catch (error) {
    next(error);
  }
};

const updateTask = async (req, res, next) => {
  try {
    const task = await taskService.updateTask(req.params.id, req.user.id, req.body);
    return sendResponse(res, 200, 'Task updated successfully', task);
  } catch (error) {
    next(error);
  }
};

const deleteTask = async (req, res, next) => {
  try {
    await taskService.deleteTask(req.params.id, req.user.id);
    return sendResponse(res, 204, 'Task deleted successfully');
  } catch (error) {
    next(error);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const task = await taskService.updateStatus(req.params.id, req.user.id, req.body.status);
    return sendResponse(res, 200, 'Task status updated successfully', task);
  } catch (error) {
    next(error);
  }
};

module.exports = { getTasks, getTaskById, createTask, updateTask, deleteTask, updateStatus };
