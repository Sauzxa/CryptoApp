import { Request, Response } from 'express';
import Region from '../models/Region';
import { ValidationError, NotFoundError, DatabaseError } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';
import { v4 as uuidv4 } from 'uuid';

// REGION ENDPOINTS

// Create a new region
export const createRegion = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { name } = req.body;

    if (!name || typeof name !== 'string') {
      throw new ValidationError('Region name is required and must be a string');
    }

    const trimmedName = name.trim();
    if (trimmedName.length === 0) {
      throw new ValidationError('Region name cannot be empty');
    }

    // Check if region already exists
    const existingRegion = await Region.findOne({ name: trimmedName });
    if (existingRegion) {
      throw new ValidationError(`Region "${trimmedName}" already exists`);
    }

    const region = new Region({
      id: uuidv4(),
      name: trimmedName,
      apartments: []
    });

    const savedRegion = await region.save();

    res.status(201).json({
      success: true,
      message: 'Region created successfully',
      data: savedRegion
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Get all regions with apartments
export const getAllRegions = asyncHandler(async (req: Request, res: Response) => {
  try {
    const regions = await Region.find().sort({ name: 1 });

    res.status(200).json({
      success: true,
      message: 'Regions retrieved successfully',
      count: regions.length,
      data: regions
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to retrieve regions');
  }
});

// Delete a region and all its apartments
export const deleteRegion = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId } = req.params;

    if (!regionId) {
      throw new ValidationError('Region ID is required');
    }

    const deletedRegion = await Region.findOneAndDelete({ id: regionId });
    
    if (!deletedRegion) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Region deleted successfully',
      data: deletedRegion
    });
  } catch (error: any) {
    throw error;
  }
});

// APARTMENT ENDPOINTS

// Add a new apartment to a region
export const addApartment = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId } = req.params;
    const { imageUrl, description, types } = req.body;

    // Validate required fields
    if (!imageUrl || !description) {
      throw new ValidationError('ImageUrl and description are required');
    }

    if (typeof imageUrl !== 'string' || typeof description !== 'string') {
      throw new ValidationError('ImageUrl and description must be strings');
    }

    // Validate image URL
    const urlPattern = /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)$/i;
    const cloudinaryPattern = /^https:\/\/res\.cloudinary\.com\//;
    if (!urlPattern.test(imageUrl) && !cloudinaryPattern.test(imageUrl)) {
      throw new ValidationError('Please provide a valid image URL');
    }

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Create apartment
    const apartment = {
      id: uuidv4(),
      imageUrl: imageUrl.trim(),
      description: description.trim(),
      types: types && Array.isArray(types) ? types.map((type: any) => ({
        id: uuidv4(),
        name: typeof type === 'string' ? type.trim() : (type.name || '').trim()
      })) : []
    };

    // Add apartment to region
    region.apartments.push(apartment);
    const savedRegion = await region.save();

    res.status(201).json({
      success: true,
      message: 'Apartment added successfully',
      data: apartment
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Update apartment details
export const updateApartment = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId, apartmentId } = req.params;
    const { imageUrl, description, types } = req.body;

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Find the apartment
    const apartment = region.apartments.find(apt => apt.id === apartmentId);
    if (!apartment) {
      throw new NotFoundError(`Apartment with ID ${apartmentId} not found`);
    }

    // Update fields if provided
    if (imageUrl !== undefined) {
      if (typeof imageUrl !== 'string') {
        throw new ValidationError('ImageUrl must be a string');
      }
      const urlPattern = /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)$/i;
      const cloudinaryPattern = /^https:\/\/res\.cloudinary\.com\//;
      if (!urlPattern.test(imageUrl) && !cloudinaryPattern.test(imageUrl)) {
        throw new ValidationError('Please provide a valid image URL');
      }
      apartment.imageUrl = imageUrl.trim();
    }

    if (description !== undefined) {
      if (typeof description !== 'string') {
        throw new ValidationError('Description must be a string');
      }
      apartment.description = description.trim();
    }

    if (types !== undefined) {
      if (!Array.isArray(types)) {
        throw new ValidationError('Types must be an array');
      }
      apartment.types = types.map((type: any) => ({
        id: type.id || uuidv4(),
        name: typeof type === 'string' ? type.trim() : (type.name || '').trim()
      }));
    }

    const savedRegion = await region.save();

    res.status(200).json({
      success: true,
      message: 'Apartment updated successfully',
      data: apartment
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Delete an apartment
export const deleteApartment = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId, apartmentId } = req.params;

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Find apartment index
    const apartmentIndex = region.apartments.findIndex(apt => apt.id === apartmentId);
    if (apartmentIndex === -1) {
      throw new NotFoundError(`Apartment with ID ${apartmentId} not found`);
    }

    // Remove apartment
    const deletedApartment = region.apartments[apartmentIndex];
    region.apartments.splice(apartmentIndex, 1);
    await region.save();

    res.status(200).json({
      success: true,
      message: 'Apartment deleted successfully',
      data: deletedApartment
    });
  } catch (error: any) {
    throw error;
  }
});

// TYPE ENDPOINTS

// Add a new type to an apartment
export const addType = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId, apartmentId } = req.params;
    const { name } = req.body;

    if (!name || typeof name !== 'string') {
      throw new ValidationError('Type name is required and must be a string');
    }

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Find the apartment
    const apartment = region.apartments.find(apt => apt.id === apartmentId);
    if (!apartment) {
      throw new NotFoundError(`Apartment with ID ${apartmentId} not found`);
    }

    // Create new type
    const newType = {
      id: uuidv4(),
      name: name.trim()
    };

    // Add type to apartment
    apartment.types.push(newType);
    await region.save();

    res.status(201).json({
      success: true,
      message: 'Type added successfully',
      data: newType
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Update a type name
export const updateType = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId, apartmentId, typeId } = req.params;
    const { name } = req.body;

    if (!name || typeof name !== 'string') {
      throw new ValidationError('Type name is required and must be a string');
    }

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Find the apartment
    const apartment = region.apartments.find(apt => apt.id === apartmentId);
    if (!apartment) {
      throw new NotFoundError(`Apartment with ID ${apartmentId} not found`);
    }

    // Find the type
    const type = apartment.types.find(t => t.id === typeId);
    if (!type) {
      throw new NotFoundError(`Type with ID ${typeId} not found`);
    }

    // Update type name
    type.name = name.trim();
    await region.save();

    res.status(200).json({
      success: true,
      message: 'Type updated successfully',
      data: type
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Delete a type
export const deleteType = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { regionId, apartmentId, typeId } = req.params;

    // Find the region
    const region = await Region.findOne({ id: regionId });
    if (!region) {
      throw new NotFoundError(`Region with ID ${regionId} not found`);
    }

    // Find the apartment
    const apartment = region.apartments.find(apt => apt.id === apartmentId);
    if (!apartment) {
      throw new NotFoundError(`Apartment with ID ${apartmentId} not found`);
    }

    // Find type index
    const typeIndex = apartment.types.findIndex(t => t.id === typeId);
    if (typeIndex === -1) {
      throw new NotFoundError(`Type with ID ${typeId} not found`);
    }

    // Remove type
    const deletedType = apartment.types[typeIndex];
    apartment.types.splice(typeIndex, 1);
    await region.save();

    res.status(200).json({
      success: true,
      message: 'Type deleted successfully',
      data: deletedType
    });
  } catch (error: any) {
    throw error;
  }
});
