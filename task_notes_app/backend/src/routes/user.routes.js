const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/profile', authController.getProfile);

router.put(
  '/profile',
  validate([
    body('firstName').optional().trim().notEmpty().withMessage('First name cannot be empty'),
    body('lastName').optional().trim().notEmpty().withMessage('Last name cannot be empty'),
    body('avatarUrl').optional().isURL().withMessage('Avatar URL must be a valid URL')
  ]),
  authController.updateProfile
);

module.exports = router;
