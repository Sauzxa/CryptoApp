import app from './app';
// import dotenv from 'dotenv';   // Removed because we set env via Docker
import mongoose from 'mongoose';
import { verifyCloudinaryConfig } from './config/cloudinary';
import Admin from './models/Admin';

// We don't need dotenv in production because we set env vars via Docker
// Only use dotenv in development
// if (process.env.NODE_ENV !== 'production') {
//   dotenv.config();
// }

const PORT = process.env.PORT || 8000;
const MONGO_URL = process.env.MONGODB_URI;

console.log(`MongoDB URI: ${MONGO_URL ? 'set' : 'not set'}`);

// Validate required environment variables
if (!MONGO_URL) {
  console.error('Error: MONGODB_URI environment variable is required');
  process.exit(1);
}

// Verify Cloudinary configuration
verifyCloudinaryConfig();

// Connect to MongoDB
mongoose.connect(MONGO_URL)
  .then(async () => {
    console.log('✅ MongoDB connected successfully');
    
    try {
      // Initialize admin if none exists
      console.log('Checking for existing dashboard admin accounts...');
      const adminCount = await Admin.countDocuments();
      console.log(`Found ${adminCount} dashboard admin accounts`);
      
      if (adminCount === 0) {
        console.log('No dashboard admin found. Creating initial dashboard admin...');
        const email = process.env.SUPER_ADMIN_EMAIL;
        const password = process.env.SUPER_ADMIN_PASS;
        
        if (!email || !password) {
          console.error('❌ SUPER_ADMIN_EMAIL and SUPER_ADMIN_PASS must be set in environment variables');
        } else {
          try {
            const admin = new Admin({ email, password });
            await admin.save();
            console.log(`✅ Initial dashboard admin created: ${email}`);
          } catch (err) {
            console.error('❌ Error creating initial dashboard admin:', err);
          }
        }
      } else {
        console.log('✅ Dashboard admin account already exists');
      }
    } catch (err) {
      console.error('❌ Error during admin initialization:', err);
    }
  })
  .catch((err: any) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  mongoose.connection.close().then(() => {
    console.log('MongoDB connection closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  mongoose.connection.close().then(() => {
    console.log('MongoDB connection closed');
    process.exit(0);
  });
});