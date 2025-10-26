import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import Admin from '../models/Admin';
import { AppError } from '../utils/errors';
import { isTokenBlacklisted } from '../controllers/authController';

// Extend Request interface to include admin
declare global {
  namespace Express {
    interface Request {
      admin?: any;
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-key';

// Protect routes - require valid JWT token
export const protect = async (req: Request, res: Response, next: NextFunction) => {
  try {
    // 1. Get token from header
    let token: string | undefined;
    
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Access denied. No token provided.'
        }
      });
    }

    // 2. Check if token is blacklisted
    if (isTokenBlacklisted(token)) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Token has been invalidated. Please login again.'
        }
      });
    }

    // 3. Verify token
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (error: any) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          error: {
            message: 'Token expired. Please login again.'
          }
        });
      }
      
      if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          error: {
            message: 'Invalid token. Please login again.'
          }
        });
      }

      return res.status(401).json({
        success: false,
        error: {
          message: 'Token verification failed.'
        }
      });
    }

    // 4. Check if admin still exists
    const admin = await Admin.findById(decoded.adminId);
    if (!admin) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Admin account no longer exists.'
        }
      });
    }

    // 5. Grant access to protected route
    req.admin = admin;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      error: {
        message: 'Authentication error'
      }
    });
  }
};
