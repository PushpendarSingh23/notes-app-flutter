const express = require('express');
const { body, param } = require('express-validator');
const taskController = require('../controllers/task.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');

const router = express.Router();

router.use(authenticate);

router.route('/')
  .get(taskController.getTasks)
  .post(
    validate([
      body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 255 }),
      body('description').optional().isString(),
      body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).withMessage('Invalid priority value'),
      body('dueDate').optional().isISO8601().withMessage('dueDate must be a valid ISO8601 date'),
      body('subtasks').optional().isArray().withMessage('subtasks must be an array')
    ]),
    taskController.createTask
  );

router.route('/:id')
  .get(
    validate([param('id').isUUID(4).withMessage('Invalid task ID format')]),
    taskController.getTaskById
  )
  .put(
    validate([
      param('id').isUUID(4).withMessage('Invalid task ID format'),
      body('title').optional().trim().notEmpty().isLength({ max: 255 }),
      body('status').optional().isIn(['TODO', 'IN_PROGRESS', 'COMPLETED']).withMessage('Invalid status value'),
      body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).withMessage('Invalid priority value'),
      body('version').isInt({ min: 1 }).withMessage('Valid version integer is required for synchronization')
    ]),
    taskController.updateTask
  )
  .delete(
    validate([param('id').isUUID(4).withMessage('Invalid task ID format')]),
    taskController.deleteTask
  );

router.patch(
  '/:id/status',
  validate([
    param('id').isUUID(4).withMessage('Invalid task ID format'),
    body('status').isIn(['TODO', 'IN_PROGRESS', 'COMPLETED']).withMessage('Invalid status value')
  ]),
  taskController.updateStatus
);

module.exports = router;
