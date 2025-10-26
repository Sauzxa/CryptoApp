import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ValidationError, NotFoundError } from '../utils/errors';
import HeroSectionNumbers from '../models/HeroSectionNumbers';

// Get hero section numbers
export const getHeroSectionNumbers = asyncHandler(async (req: Request, res: Response) => {
  try {
    let heroNumbers = await HeroSectionNumbers.findOne();

    // If no document exists, create one with default values
    if (!heroNumbers) {
      heroNumbers = new HeroSectionNumbers({
        propertiesListed: "5,200+",
        happyClients: "1,800+",
        daysToClose: "Average 14"
      });
      await heroNumbers.save();
    }

    res.status(200).json({
      success: true,
      message: 'Hero section numbers retrieved successfully',
      data: heroNumbers
    });
  } catch (error: any) {
    console.error('Failed to retrieve hero section numbers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve hero section numbers',
      error: error.message
    });
  }
});

// Update hero section numbers
export const updateHeroSectionNumbers = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { propertiesListed, happyClients, daysToClose } = req.body;

    // Validation
    if (!propertiesListed || !happyClients || !daysToClose) {
      throw new ValidationError('All fields are required: propertiesListed, happyClients, daysToClose');
    }

    // Validate field lengths
    if (propertiesListed.length > 20) {
      throw new ValidationError('Properties listed cannot exceed 20 characters');
    }
    if (happyClients.length > 20) {
      throw new ValidationError('Happy clients cannot exceed 20 characters');
    }
    if (daysToClose.length > 20) {
      throw new ValidationError('Days to close cannot exceed 20 characters');
    }

    // Find existing document or create new one
    let heroNumbers = await HeroSectionNumbers.findOne();

    if (heroNumbers) {
      // Update existing document
      heroNumbers.propertiesListed = propertiesListed.trim();
      heroNumbers.happyClients = happyClients.trim();
      heroNumbers.daysToClose = daysToClose.trim();
      await heroNumbers.save();
    } else {
      // Create new document
      heroNumbers = new HeroSectionNumbers({
        propertiesListed: propertiesListed.trim(),
        happyClients: happyClients.trim(),
        daysToClose: daysToClose.trim()
      });
      await heroNumbers.save();
    }

    res.status(200).json({
      success: true,
      message: 'Hero section numbers updated successfully',
      data: heroNumbers
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      res.status(400).json({
        success: false,
        message: 'Validation error',
        error: error.message
      });
    } else {
      console.error('Failed to update hero section numbers:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update hero section numbers',
        error: error.message
      });
    }
  }
});
