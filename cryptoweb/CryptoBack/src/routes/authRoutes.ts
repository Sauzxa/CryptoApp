import { Router } from 'express';
import { login, logout, createInitialAdmin } from '../controllers/authController';
import { protect } from '../middleware/auth';

const router = Router();

// POST /setup - Create initial admin (public route, one-time only)
router.post('/setup', createInitialAdmin);

// POST /login - Admin login (public route)
router.post('/login', login);

// POST /logout - Admin logout (protected route)
router.post('/logout', protect, logout);

export default router;
