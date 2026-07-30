const express = require('express');
const { body, param } = require('express-validator');
const noteController = require('../controllers/note.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');

const router = express.Router();

router.use(authenticate);

router.route('/')
  .get(noteController.getNotes)
  .post(
    validate([
      body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 255 }),
      body('content').optional().isString(),
      body('colorHex').optional().matches(/^#[0-9A-F]{6}$/i).withMessage('Invalid hex color')
    ]),
    noteController.createNote
  );

router.route('/:id')
  .get(
    validate([param('id').isUUID(4).withMessage('Invalid note ID format')]),
    noteController.getNoteById
  )
  .put(
    validate([
      param('id').isUUID(4).withMessage('Invalid note ID format'),
      body('title').optional().trim().notEmpty().isLength({ max: 255 }),
      body('version').isInt({ min: 1 }).withMessage('Valid version integer is required for synchronization')
    ]),
    noteController.updateNote
  )
  .delete(
    validate([param('id').isUUID(4).withMessage('Invalid note ID format')]),
    noteController.deleteNote
  );

router.patch(
  '/:id/archive',
  validate([
    param('id').isUUID(4).withMessage('Invalid note ID format'),
    body('isArchived').isBoolean().withMessage('isArchived must be a boolean')
  ]),
  noteController.toggleArchive
);

router.patch(
  '/:id/pin',
  validate([
    param('id').isUUID(4).withMessage('Invalid note ID format'),
    body('isPinned').isBoolean().withMessage('isPinned must be a boolean')
  ]),
  noteController.togglePin
);

module.exports = router;
