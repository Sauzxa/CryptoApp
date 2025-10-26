import { Router } from 'express';
import {
  // Region endpoints
  createRegion,
  getAllRegions,
  deleteRegion,
  // Apartment endpoints
  addApartment,
  updateApartment,
  deleteApartment,
  // Type endpoints
  addType,
  updateType,
  deleteType
} from '../controllers/bestSellersController';
import { protect } from '../middleware/auth';

const router = Router();

// GET /bestsellers/regions - Fetch all regions with apartments (public)
router.get('/regions', getAllRegions);

// Apply JWT protection to admin best sellers routes
router.use(protect);

// REGION ROUTES
// POST /bestsellers/regions - Add a new region
router.post('/regions', createRegion);

// DELETE /bestsellers/regions/:regionId - Remove a region and all its apartments
router.delete('/regions/:regionId', deleteRegion);

// APARTMENT ROUTES (inside a region)
// POST /bestsellers/regions/:regionId/apartments - Add a new apartment
router.post('/regions/:regionId/apartments', addApartment);

// PUT /bestsellers/regions/:regionId/apartments/:apartmentId - Update apartment details
router.put('/regions/:regionId/apartments/:apartmentId', updateApartment);

// DELETE /bestsellers/regions/:regionId/apartments/:apartmentId - Delete an apartment
router.delete('/regions/:regionId/apartments/:apartmentId', deleteApartment);

// TYPE ROUTES (inside an apartment)
// POST /bestsellers/regions/:regionId/apartments/:apartmentId/types - Add a new type
router.post('/regions/:regionId/apartments/:apartmentId/types', addType);

// PUT /bestsellers/regions/:regionId/apartments/:apartmentId/types/:typeId - Update type name
router.put('/regions/:regionId/apartments/:apartmentId/types/:typeId', updateType);

// DELETE /bestsellers/regions/:regionId/apartments/:apartmentId/types/:typeId - Delete a type
router.delete('/regions/:regionId/apartments/:apartmentId/types/:typeId', deleteType);

export default router;
