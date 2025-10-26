import { Request, Response } from 'express';
import User from '../models/User';
import { validateCreateUser, validateUpdateStatus, validateObjectId } from '../utils/validation';
import { NotFoundError, DatabaseError } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';

// Create a new reservation
export const createUser = asyncHandler(async (req: Request, res: Response) => {
  try {
    // Validate input data
    const validatedData = validateCreateUser(req.body);

    // Create new user/reservation
    const newUser = new User(validatedData);
    const savedUser = await newUser.save();

    res.status(201).json({
      success: true,
      message: 'Reservation created successfully',
      data: savedUser
    });
  } catch (error: any) {
    if (error.name === 'ValidationError') {
      throw new DatabaseError(`Database validation error: ${error.message}`);
    }
    throw error;
  }
});

// Get all reservations
export const getAllUsers = asyncHandler(async (req: Request, res: Response) => {
  try {
    const users = await User.find().sort({ reservationDate: -1 }); // Sort by newest first

    res.status(200).json({
      success: true,
      message: 'Users retrieved successfully',
      count: users.length,
      data: users
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to retrieve reservations');
  }
});

// Update reservation status
export const updateUserStatus = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    // Validate ID format
    validateObjectId(id);
    
    // Validate status data
    const { status } = validateUpdateStatus(req.body);

    // Find and update user
    const updatedUser = await User.findByIdAndUpdate(
      id,
      { status },
      { new: true, runValidators: true }
    );

    if (!updatedUser) {
      throw new NotFoundError(`Reservation with ID ${id} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Reservation status updated successfully',
      data: updatedUser
    });
  } catch (error: any) {
    if (error.name === 'CastError') {
      throw new NotFoundError(`Reservation with ID ${req.params.id} not found`);
    }
    throw error;
  }
});

// Get total count of reservations
export const getTotalCount = asyncHandler(async (req: Request, res: Response) => {
  try {
    const count = await User.countDocuments();

    res.status(200).json({
      success: true,
      count
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to get total count');
  }
});

// Get count of completed reservations
export const getDoneCount = asyncHandler(async (req: Request, res: Response) => {
  try {
    const count = await User.countDocuments({ status: 'Done' });

    res.status(200).json({
      success: true,
      count
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to get done count');
  }
});

// Get count of pending reservations
export const getPendingCount = asyncHandler(async (req: Request, res: Response) => {
  try {
    const count = await User.countDocuments({ status: 'Pending' });

    res.status(200).json({
      success: true,
      count
    });
  } catch (error: any) {
    throw new DatabaseError('Failed to get pending count');
  }
});

// Delete a reservation by ID
export const deleteOrder = asyncHandler(async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    // Validate ID format
    validateObjectId(id);

    // Find and delete the reservation
    const deletedUser = await User.findByIdAndDelete(id);

    if (!deletedUser) {
      throw new NotFoundError(`Reservation with ID ${id} not found`);
    }

    res.status(200).json({
      success: true,
      message: 'Reservation deleted successfully',
      data: deletedUser
    });
  } catch (error: any) {
    if (error.name === 'CastError') {
      throw new NotFoundError(`Reservation with ID ${req.params.id} not found`);
    }
    throw error;
  }
});
