import { Request, Response } from 'express';
import DashboardDiv from '../models/DashboardDiv';
import { ValidationError, NotFoundError, DatabaseError } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';

// Initialize or update a dashboard div
export const upsertDashboardDiv = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id, photoUrl, price, apartment } = req.body;

    // Validate required fields
    if (!id || !photoUrl || price === undefined || !apartment) {
      throw new ValidationError('All fields are required: id, photoUrl, price, apartment');
    }

    // Validate ID is 1, 2, or 3
    if (![1, 2, 3].includes(Number(id))) {
      throw new ValidationError('ID must be 1, 2, or 3');
    }

    // Validate price is a positive number
    if (typeof price !== 'number' || price < 0 || !Number.isFinite(price)) {
      throw new ValidationError('Price must be a positive number');
    }

    // Validate strings
    if (typeof photoUrl !== 'string' || typeof apartment !== 'string') {
      throw new ValidationError('PhotoUrl and apartment must be strings');
    }

    // Validate URL format (more flexible to allow query parameters)
    const urlPattern = /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i;
    const cloudinaryPattern = /^https:\/\/res\.cloudinary\.com\//;
    const unsplashPattern = /^https:\/\/images\.unsplash\.com\//;
    if (!urlPattern.test(photoUrl) && !cloudinaryPattern.test(photoUrl) && !unsplashPattern.test(photoUrl)) {
      throw new ValidationError('Please provide a valid image URL');
    }

    // Update or create the div
    const updatedDiv = await DashboardDiv.findOneAndUpdate(
      { id: Number(id) },
      {
        id: Number(id),
        photoUrl: photoUrl.trim(),
        price: Number(price),
        apartment: apartment.trim()
      },
      { 
        new: true, 
        upsert: true, 
        runValidators: true 
      }
    );

    res.status(200).json({
      success: true,
      message: `Dashboard div ${id} updated successfully`,
      data: updatedDiv
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Update a specific dashboard div
export const updateDashboardDiv = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { photoUrl, price, apartment } = req.body;

    // Validate ID
    const divId = Number(id);
    if (![1, 2, 3].includes(divId)) {
      throw new ValidationError('ID must be 1, 2, or 3');
    }

    // Build update object with only provided fields
    const updateData: any = {};
    
    if (photoUrl !== undefined) {
      if (typeof photoUrl !== 'string') {
        throw new ValidationError('PhotoUrl must be a string');
      }
      const urlPattern = /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$/i;
      const cloudinaryPattern = /^https:\/\/res\.cloudinary\.com\//;
      const unsplashPattern = /^https:\/\/images\.unsplash\.com\//;
      if (!urlPattern.test(photoUrl) && !cloudinaryPattern.test(photoUrl) && !unsplashPattern.test(photoUrl)) {
        throw new ValidationError('Please provide a valid image URL');
      }
      updateData.photoUrl = photoUrl.trim();
    }

    if (price !== undefined) {
      if (typeof price !== 'number' || price < 0 || !Number.isFinite(price)) {
        throw new ValidationError('Price must be a positive number');
      }
      updateData.price = Number(price);
    }

    if (apartment !== undefined) {
      if (typeof apartment !== 'string') {
        throw new ValidationError('Apartment must be a string');
      }
      updateData.apartment = apartment.trim();
    }

    // Check if div exists
    const existingDiv = await DashboardDiv.findOne({ id: divId });
    if (!existingDiv) {
      throw new NotFoundError(`Dashboard div with ID ${divId} not found`);
    }

    // Update the div
    const updatedDiv = await DashboardDiv.findOneAndUpdate(
      { id: divId },
      updateData,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: `Dashboard div ${divId} updated successfully`,
      data: updatedDiv
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Get all dashboard divs
export const getAllDashboardDivs = asyncHandler(async (req: Request, res: Response) => {
  try {
    const divs = await DashboardDiv.find().sort({ id: 1 }); // Sort by ID (1, 2, 3)

    res.status(200).json({
      success: true,
      message: 'Dashboard divs retrieved successfully',
      count: divs.length,
      data: divs
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to retrieve dashboard divs');
  }
});

// Get a specific dashboard div
export const getDashboardDiv = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const divId = Number(id);

    // Validate ID
    if (![1, 2, 3].includes(divId)) {
      throw new ValidationError('ID must be 1, 2, or 3');
    }

    const div = await DashboardDiv.findOne({ id: divId });
    
    if (!div) {
      throw new NotFoundError(`Dashboard div with ID ${divId} not found`);
    }

    res.status(200).json({
      success: true,
      message: `Dashboard div ${divId} retrieved successfully`,
      data: div
    });
  } catch (error: any) {
    throw error;
  }
});
