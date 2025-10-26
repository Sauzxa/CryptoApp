# Crypto Immobilier Backend

A secure and scalable Node.js backend for managing real estate reservations, built with **Express.js**, **TypeScript**, **Cloudinary**, and **MongoDB**.

## Features

- 🚀 **Express.js** with TypeScript  
- 🔐 **JWT Authentication** with super admin access  
- 🔒 **Secure Password Hashing** with bcrypt  
- 🚪 **Login/Logout System** with token invalidation  
- 🛡️ **Protected Routes** - All reservation endpoints require authentication  
- 🛡️ **Security middlewares** (Helmet, CORS, NoSQL injection protection)  
- 📝 **Request logging** with Morgan  
- 🗄️ **MongoDB** integration with Mongoose  
- 🏠 **Reservation Management System** with full CRUD operations  
- ✅ **Data Validation** with custom validation utilities  
- 📊 **Statistics Endpoints** for tracking reservations  
- 👑 **Super Admin Management** with automated seeding  
- 🎨 **Dashboard FYH Section** - Manage 3 featured property cards  
- 🏆 **Best Sellers Management** - Region-based apartment listings with types  
- ☁️ **Cloudinary Integration** for image management  
- 🔧 **Development tools** (Nodemon, TypeScript compilation)  
- ⚡ **Hot reload** for development  
- 🔒 **Environment-based configuration**  
- 💥 **Comprehensive error handling**  
- 🎯 **Graceful shutdown handling**  
- 📁 **Modular Architecture** with separate routes, controllers, models, and utilities  

---

## Prerequisites

- Node.js (v16 or higher)  
- MongoDB (local or MongoDB Atlas)  
- npm or yarn  

---

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd crypto-immobilier-back
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**  
   Create a `.env` file in the root directory:

   ```env
   # Server Configuration
   PORT=8000
   NODE_ENV=development

   # Database Configuration
   MONGODB_URI=mongodb://localhost:27017/crypto-immobilier

   # Frontend Configuration (for CORS)
   FRONTEND_URL=http://localhost:3000

   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-here
   JWT_EXPIRES_IN=30d

   # Cloudinary Configuration
   CLOUDINARY_CLOUD_NAME=your-cloud-name
   CLOUDINARY_API_KEY=your-api-key
   CLOUDINARY_API_SECRET=your-api-secret
   ```

   ⚠️ **Never commit `.env` files to GitHub**. Use `.gitignore` to protect sensitive data.  

---

## Scripts

- **Development**: `npm run dev` - Start with hot reload  
- **Build**: `npm run build` - Compile TypeScript to JavaScript  
- **Production**: `npm start` - Run compiled JavaScript  
- **Type Check**: `npx tsc --noEmit` - Check TypeScript types  

---

## Project Structure

```
src/
├── app.ts                    # Express app configuration and middleware
├── server.ts                 # Server startup and database connection
├── controllers/
│   ├── userController.ts     # Business logic for reservations
│   └── authController.ts     # Authentication logic (login/logout)
├── models/
│   ├── User.ts               # MongoDB schema for reservations
│   └── Admin.ts              # MongoDB schema for admin
├── routes/
│   ├── userRoutes.ts         # API route definitions for reservations
│   └── authRoutes.ts         # API route definitions for authentication
├── middleware/
│   ├── errorHandler.ts       # Global error handling middleware
│   └── auth.ts               # JWT authentication middleware
└── utils/
    ├── errors.ts             # Custom error classes
    ├── validation.ts         # Input validation utilities
    └── asyncHandler.ts       # Async error wrapper

dist/                         # Compiled JavaScript (generated)
```

---

## Security Best Practices

- Store **JWT secret** and **Cloudinary credentials** securely (e.g., `.env`, vault, or secrets manager)  
- Never expose API keys in your codebase  
- Always use HTTPS in production  
- Regularly rotate credentials  

---

## Development

1. **Start MongoDB** (if running locally)  
2. **Run development server**:
   ```bash
   npm run dev
   ```
3. **Create Initial Admin** (via Postman or HTTP client):
   - **POST** `http://localhost:8000/api/auth/setup`  
   - **Body**: `{ "email": "your-admin-email", "password": "your-password" }`  
4. **Server ready** at `http://localhost:8000`  

---

## Production Deployment

1. **Build the project**:
   ```bash
   npm run build
   ```
2. **Set production environment variables** securely  
3. **Start the server**:
   ```bash
   npm start
   ```

---

## License

This project is licensed under the ISC License.  
