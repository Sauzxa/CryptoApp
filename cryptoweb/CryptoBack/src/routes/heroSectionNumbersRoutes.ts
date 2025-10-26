import express from 'express';
import {
  getHeroSectionNumbers,
  updateHeroSectionNumbers
} from '../controllers/heroSectionNumbersController';
import { protect } from '../middleware/auth';

const router = express.Router();

// GET /hero-section-numbers - Get hero section numbers (public)
router.get('/', getHeroSectionNumbers);

// Apply authentication middleware to admin routes
router.use(protect);

// PUT /hero-section-numbers - Update hero section numbers
router.put('/', updateHeroSectionNumbers);

export default router;
