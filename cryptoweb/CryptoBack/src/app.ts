import express, { NextFunction, Request, Response } from "express";
import helmet from "helmet";
import morgan from "morgan";
import mongoSanitize from "express-mongo-sanitize";
import cors from "cors";

// Import routes
import userRoutes from './routes/userRoutes';
import authRoutes from './routes/authRoutes';
import dashboardRoutes from './routes/dashboardRoutes';
import bestSellersRoutes from './routes/bestSellersRoutes';
import apartmentTypeRoutes from './routes/apartmentTypeRoutes';
import heroSectionNumbersRoutes from './routes/heroSectionNumbersRoutes';

// Import middleware
import { globalErrorHandler, notFoundHandler } from './middleware/errorHandler';

const app = express();

// Middleware setup
app.use(helmet()); // Send appropriate headers to prevent XSS attacks
app.use(express.json()); // Parse JSON request body
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(morgan('combined')); // HTTP request logger
app.use(mongoSanitize()); // Prevent NoSQL injection attacks
app.use(cors({
  credentials: true,
  origin: true // Allow all origins
})); // Configure CORS properly

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Server is running successfully',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/bestsellers', bestSellersRoutes);
app.use('/api/apartment-types', apartmentTypeRoutes);
app.use('/api/hero-section-numbers', heroSectionNumbersRoutes);

// API info endpoint
app.get('/api', (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Crypto Immobilier API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      // Authentication endpoints (public)
      initialSetup: 'POST /api/auth/setup',
      login: 'POST /api/auth/login',
      logout: 'POST /api/auth/logout',
      // Reservation endpoints (protected - requires JWT)
      users: '/api/users',
      createReservation: 'POST /api/users',
      getAllReservations: 'GET /api/users',
      updateStatus: 'PUT /api/users/:id/status',
      totalCount: 'GET /api/users/count',
      doneCount: 'GET /api/users/count/done',
      pendingCount: 'GET /api/users/count/pending',
      // Dashboard endpoints (protected - requires JWT)
      dashboardDivs: 'GET /api/dashboard/divs',
      createOrUpdateDiv: 'POST /api/dashboard/divs',
      updateDiv: 'PUT /api/dashboard/divs/:id',
      // Best Sellers endpoints (protected - requires JWT)
      regions: 'GET /api/bestsellers/regions',
      createRegion: 'POST /api/bestsellers/regions',
      apartments: 'POST /api/bestsellers/regions/:regionId/apartments',
      types: 'POST /api/bestsellers/regions/:regionId/apartments/:apartmentId/types',
      // Apartment Types endpoints (protected - requires JWT)
      apartmentTypes: 'GET /api/apartment-types',
      createApartmentType: 'POST /api/apartment-types',
      getApartmentType: 'GET /api/apartment-types/:id',
      updateApartmentType: 'PUT /api/apartment-types/:id',
      deleteApartmentType: 'DELETE /api/apartment-types/:id',
      // Hero Section Numbers endpoints (protected - requires JWT)
      heroSectionNumbers: 'GET /api/hero-section-numbers',
      updateHeroSectionNumbers: 'PUT /api/hero-section-numbers'
    }
  });
});

// Handle unhandled routes
app.all("*", notFoundHandler);

// Global error handling middleware
app.use(globalErrorHandler);

  export default app; 