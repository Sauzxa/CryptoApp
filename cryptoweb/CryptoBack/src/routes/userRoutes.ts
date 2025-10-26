import { Router } from 'express';
import {
  createUser,
  getAllUsers,
  updateUserStatus,
  getTotalCount,
  getDoneCount,
  getPendingCount,
  deleteOrder
} from '../controllers/userController';
import { protect } from '../middleware/auth';

const router = Router();

// POST /users - Create a new reservation (public - no JWT required)
router.post('/', createUser);

// Apply JWT protection to admin routes only
router.use(protect);

// GET /users - Get all reservations (protected)
router.get('/', getAllUsers);

// PUT /users/:id/status - Update reservation status (protected)
router.put('/:id/status', updateUserStatus);

// GET /users/count - Get total count of reservations (protected)
router.get('/count', getTotalCount);

// GET /users/count/done - Get count of completed reservations (protected)
router.get('/count/done', getDoneCount);

// GET /users/count/pending - Get count of pending reservations (protected)
router.get('/count/pending', getPendingCount);

// DELETE /users/:id - Delete a reservation by ID (protected - admin only)
router.delete('/:id', deleteOrder);

export default router;
