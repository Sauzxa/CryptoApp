import { Request, Response } from 'express';
import ApartmentType from '../models/ApartmentType';
import { NotFoundError, DatabaseError } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';

// Validation function for apartment type data
const validateApartmentType = (data: any) => {
  if (!data.name || typeof data.name !== 'string') {
    throw new Error('Apartment type name is required and must be a string');
  }
  
  if (data.name.trim().length === 0) {
    throw new Error('Apartment type name cannot be empty');
  }
  
  if (data.name.length > 50) {
    throw new Error('Apartment type name cannot exceed 50 characters');
  }
  
  return {
    name: data.name.trim()
  };
};

// Create a new apartment type
export const createApartmentType = asyncHandler(async (req: Request, res: Response) => {
  try {
    // Validate input data
    const validatedData = validateApartmentType(req.body);

    // Check if apartment type with the same name already exists
    const existingType = await ApartmentType.findOne({ name: validatedData.name });
    if (existingType) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Apartment type with this name already exists'
        }
      });
    }

    // Create new apartment type
    const newApartmentType = new ApartmentType(validatedData);
    const savedApartmentType = await newApartmentType.save();

    res.status(201).json({
      success: true,
      message: 'Apartment type created successfully',
      data: savedApartmentType
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Get all apartment types
export const getAllApartmentTypes = asyncHandler(async (req: Request, res: Response) => {
  try {
    const apartmentTypes = await ApartmentType.find().sort({ name: 1 }); // Sort alphabetically

    res.status(200).json({
      success: true,
      message: 'Apartment types retrieved successfully',
      count: apartmentTypes.length,
      data: apartmentTypes
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to retrieve apartment types');
  }
});



// Get apartment type by ID
export const getApartmentTypeById = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    const apartmentType = await ApartmentType.findOne({ id });

    if (!apartmentType) {
      throw new NotFoundError(`Apartment type with ID ${id} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Apartment type retrieved successfully',
      data: apartmentType
    });
  } catch (error: any) {
    throw error;
  }
});

// Update apartment type
export const updateApartmentType = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    // Validate input data
    const validatedData = validateApartmentType(req.body);

    // Check if another apartment type with the same name exists (excluding current one)
    const existingType = await ApartmentType.findOne({ 
      name: validatedData.name,
      id: { $ne: id }
    });
    
    if (existingType) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Another apartment type with this name already exists'
        }
      });
    }

    // Find and update apartment type
    const updatedApartmentType = await ApartmentType.findOneAndUpdate(
      { id },
      validatedData,
      { new: true, runValidators: true }
    );

    if (!updatedApartmentType) {
      throw new NotFoundError(`Apartment type with ID ${id} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Apartment type updated successfully',
      data: updatedApartmentType
    });
  } catch (error: any) {
    throw error;
  }
});

// Delete apartment type
export const deleteApartmentType = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const deletedApartmentType = await ApartmentType.findOneAndDelete({ id });

    if (!deletedApartmentType) {
      throw new NotFoundError(`Apartment type with ID ${id} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Apartment type deleted successfully',
      data: deletedApartmentType
    });
  } catch (error: any) {
    throw error;
  }
});
