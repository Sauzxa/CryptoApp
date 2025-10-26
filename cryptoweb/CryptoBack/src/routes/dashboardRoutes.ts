import { Router } from 'express';
import {
  upsertDashboardDiv,
  updateDashboardDiv,
  getAllDashboardDivs,
  getDashboardDiv
} from '../controllers/dashboardController';
import { protect } from '../middleware/auth';

const router = Router();

// GET /dashboard/divs - Get all dashboard divs (public)
router.get('/divs', getAllDashboardDivs);

// GET /dashboard/divs/:id - Get a specific dashboard div (public)
router.get('/divs/:id', getDashboardDiv);

// Apply JWT protection to admin dashboard routes
router.use(protect);

// POST /dashboard/divs - Initialize or create a dashboard div
router.post('/divs', upsertDashboardDiv);

// PUT /dashboard/divs/:id - Update a specific dashboard div
router.put('/divs/:id', updateDashboardDiv);

export default router;
