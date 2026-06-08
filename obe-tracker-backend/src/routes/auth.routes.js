const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const { authenticate } = require('../middleware/auth');
const { login, logout, forgotPassword, resetPassword } = require('../controllers/auth.controller');

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 5, message: { status: 'error', error: 'Too many attempts' } });

router.post('/login', limiter, login);
router.post('/logout', authenticate, logout);
router.post('/forgot-password', limiter, forgotPassword);
router.post('/reset-password', limiter, resetPassword);

module.exports = router;
