import { ValidationError } from './errors';

// Validation interfaces
export interface CreateUserRequest {
  name: string;
  number: string;
  message?: string;
  typeAppartement: string;
  reservationDate: Date;
}

export interface UpdateStatusRequest {
  status: 'Pending' | 'Done';
}

// Validation functions
export const validateCreateUser = (data: any): CreateUserRequest => {
  const errors: string[] = [];

  // Validate name
  if (!data.name || typeof data.name !== 'string') {
    errors.push('Name is required and must be a string');
  } else if (data.name.trim().length === 0) {
    errors.push('Name cannot be empty');
  } else if (data.name.length > 100) {
    errors.push('Name cannot exceed 100 characters');
  }

  // Validate number
  if (!data.number || typeof data.number !== 'string') {
    errors.push('Phone number is required and must be a string');
  } else if (data.number.trim().length === 0) {
    errors.push('Phone number cannot be empty');
  } else if (data.number.length > 20) {
    errors.push('Phone number cannot exceed 20 characters');
  }

  // Validate message (optional)
  if (data.message && typeof data.message !== 'string') {
    errors.push('Message must be a string');
  } else if (data.message && data.message.length > 1000) {
    errors.push('Message cannot exceed 1000 characters');
  }

  // Validate typeAppartement
  if (!data.typeAppartement || typeof data.typeAppartement !== 'string') {
    errors.push('Apartment type is required and must be a string');
  } else if (data.typeAppartement.trim().length === 0) {
    errors.push('Apartment type cannot be empty');
  } else if (data.typeAppartement.length > 50) {
    errors.push('Apartment type cannot exceed 50 characters');
  }

  // Validate reservationDate (required)
  if (!data.reservationDate) {
    errors.push('Reservation date is required');
  } else if (!isValidDate(data.reservationDate)) {
    errors.push('Reservation date must be a valid date');
  }

  if (errors.length > 0) {
    throw new ValidationError(`Validation failed: ${errors.join(', ')}`);
  }

  return {
    name: data.name.trim(),
    number: data.number.trim(),
    ...(data.message && { message: data.message.trim() }),
    typeAppartement: data.typeAppartement.trim(),
    reservationDate: new Date(data.reservationDate)
  };
};

export const validateUpdateStatus = (data: any): UpdateStatusRequest => {
  const validStatuses = ['Pending', 'Done'];
  
  if (!data.status || typeof data.status !== 'string') {
    throw new ValidationError('Status is required and must be a string');
  }

  if (!validStatuses.includes(data.status)) {
    throw new ValidationError(`Status must be one of: ${validStatuses.join(', ')}`);
  }

  return { status: data.status as 'Pending' | 'Done' };
};

export const validateObjectId = (id: string): void => {
  if (!id || typeof id !== 'string') {
    throw new ValidationError('ID is required and must be a string');
  }

  // MongoDB ObjectId validation (24 character hex string)
  const objectIdRegex = /^[0-9a-fA-F]{24}$/;
  if (!objectIdRegex.test(id)) {
    throw new ValidationError('Invalid ID format');
  }
};

// Helper functions
const isValidDate = (date: any): boolean => {
  return date instanceof Date || !isNaN(Date.parse(date));
};
