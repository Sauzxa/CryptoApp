import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import Admin from '../models/Admin';
import { ValidationError, NotFoundError } from '../utils/errors';
import { asyncHandler } from '../utils/asyncHandler';

// JWT secret from environment variables
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '30d'; // Long expiration for good UX

// In-memory token blacklist (in production, use Redis or database)
const tokenBlacklist = new Set<string>();

// Generate JWT token
const generateToken = (adminId: string): string => {
  return jwt.sign({ adminId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN
  } as jwt.SignOptions);
};

// Admin login
export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    throw new ValidationError('Email and password are required');
  }

  if (typeof email !== 'string' || typeof password !== 'string') {
    throw new ValidationError('Email and password must be strings');
  }

  // Find admin by email
  const admin = await Admin.findOne({ email: email.toLowerCase().trim() }).select('+password');
  
  if (!admin) {
    throw new NotFoundError('Invalid email or password');
  }

  // Check password
  const isPasswordValid = await admin.comparePassword(password);
  
  if (!isPasswordValid) {
    throw new NotFoundError('Invalid email or password');
  }

  // Generate JWT token
  const token = generateToken((admin._id as any).toString());

  res.status(200).json({
    success: true,
    message: 'Login successful',
    data: {
      admin: {
        id: (admin._id as any).toString(),
        email: admin.email
      },
      token
    }
  });
});

// Admin logout
export const logout = asyncHandler(async (req: Request, res: Response) => {
  // Get token from request (added by auth middleware)
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (token) {
    // Add token to blacklist
    tokenBlacklist.add(token);
  }

  res.status(200).json({
    success: true,
    message: 'Logout successful'
  });
});

// Check if token is blacklisted
export const isTokenBlacklisted = (token: string): boolean => {
  return tokenBlacklist.has(token);
};

// Create initial admin (one-time setup)
export const createInitialAdmin = asyncHandler(async (req: Request, res: Response) => {
  // Check if any admin already exists
  const existingAdmin = await Admin.countDocuments();
  
  if (existingAdmin > 0) {
    throw new ValidationError('Admin account already exists. This endpoint is only for initial setup.');
  }

  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    throw new ValidationError('Email and password are required');
  }

  if (typeof email !== 'string' || typeof password !== 'string') {
    throw new ValidationError('Email and password must be strings');
  }

  // Create admin
  const admin = new Admin({
    email: email.toLowerCase().trim(),
    password // Will be hashed automatically by pre-save middleware
  });

  await admin.save();

  res.status(201).json({
    success: true,
    message: 'Initial admin created successfully',
    data: {
      admin: {
        id: (admin._id as any).toString(),
        email: admin.email
      }
    }
  });
});

// Get admin from token (for middleware)
export const getAdminFromToken = async (token: string) => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { adminId: string };
    const admin = await Admin.findById(decoded.adminId);
    return admin;
  } catch (error) {
    return null;
  }
};
