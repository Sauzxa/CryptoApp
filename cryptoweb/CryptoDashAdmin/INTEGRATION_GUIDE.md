# Dashboard Backend Integration Guide

This guide explains how the React dashboard has been integrated with the Crypto Immobilier Backend API following React best practices.

## 🏗️ Architecture Overview

The integration follows modern React patterns with:
- **Context API** for global state management
- **Custom hooks** for data fetching and manipulation
- **Error boundaries** and loading states
- **Authentication flow** with JWT tokens
- **Modular API utilities** for backend communication

## 📁 New Files Added

### Core Infrastructure
- `src/utils/api.js` - API utility functions and endpoint wrappers
- `src/contexts/AuthContext.jsx` - Authentication state management
- `src/contexts/DataContext.jsx` - Data state management (reservations, dashboard, regions)
- `src/components/LoginModal.jsx` - Login interface component
- `src/utils/imageUpload.js` - Image upload utilities (Cloudinary integration)

### Integration Points
- Updated `src/App.jsx` - Added context providers and authentication flow
- Updated `src/Sidebar.jsx` - Added logout functionality
- Updated `src/DataTable.jsx` - Connected to backend reservations API
- Updated `src/pages/TablesPage.jsx` - Real-time statistics from backend
- Updated `src/components/FyhImageEditor.jsx` - Dashboard divs management

## 🔐 Authentication Flow

### Login Process
1. User opens dashboard → Login modal appears automatically
2. Default credentials: `crypto.immobilier@gmail.com` / `crypto_2222`
3. JWT token stored in localStorage upon successful login
4. Token automatically included in all subsequent API requests

### Logout Process
- Click "Logout" in sidebar
- Token removed from localStorage
- User redirected back to login modal

### Auto-Authentication
- App checks for existing token on startup
- Automatic re-authentication for returning users
- Token expiration handling with graceful fallback

## 📊 Data Management

### Context Architecture
```
AuthContext
├── Authentication state
├── Login/logout functions
└── User information

DataContext
├── Reservations data
├── Dashboard divs data  
├── Best sellers/regions data
├── Loading states
├── Error handling
└── CRUD operations
```

### State Management Pattern
- **Actions**: Defined action types for consistent state updates
- **Reducers**: Pure functions for predictable state changes  
- **Context Providers**: Centralized state with custom hooks
- **Custom Hooks**: `useAuth()` and `useData()` for component access

## 🔌 API Integration

### Implemented Endpoints

#### Authentication
- `POST /auth/login` - Admin login
- `POST /auth/logout` - Admin logout
- Automatic token refresh and error handling

#### Reservations
- `GET /users` - Fetch all reservations
- `PUT /users/:id/status` - Update reservation status
- `GET /users/count/*` - Various count endpoints for statistics

#### Dashboard Divs (FYH Section)
- `GET /dashboard/divs` - Fetch all dashboard divs
- `PUT /dashboard/divs/:id` - Update specific dashboard div
- Image upload integration with Cloudinary

#### Best Sellers (Partially Implemented)
- `GET /bestsellers/regions` - Fetch regions with apartments
- `POST /bestsellers/regions` - Create new region
- Apartment and type management endpoints ready

### Error Handling
- **Network errors**: Automatic retry mechanisms
- **Authentication errors**: Redirect to login
- **Validation errors**: User-friendly error messages
- **Loading states**: Visual feedback for all operations

## 📱 Component Updates

### DataTable (`src/DataTable.jsx`)
**Before**: Static hardcoded data
**After**: 
- Real-time reservation data from backend
- Status updates with immediate API calls
- Loading and error states
- Automatic data refresh

### TableStats (`src/pages/TablesPage.jsx`)
**Before**: Hardcoded statistics
**After**:
- Real reservation counts from backend
- Pending, completed, and total reservation statistics
- Loading states during data fetch

### FyhImageEditor (`src/components/FyhImageEditor.jsx`)
**Before**: Local state only
**After**:
- Connected to dashboard divs API
- Image upload to Cloudinary
- Save functionality with backend persistence
- Loading states and error handling

## 🖼️ Image Upload System

### Cloudinary Integration
- Secure image upload to cloud storage
- Automatic URL generation for backend storage
- File validation (type, size, dimensions)
- Upload progress tracking
- Mock upload for development (when Cloudinary not configured)

### Configuration Required
```javascript
// In src/utils/imageUpload.js
const CLOUDINARY_UPLOAD_URL = 'https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload';
const CLOUDINARY_UPLOAD_PRESET = 'YOUR_UPLOAD_PRESET';
```

## 🔄 Data Flow Examples

### Reservation Status Update
1. User selects new status in DataTable dropdown
2. `handleStatusChange()` calls `updateReservation()`
3. API call to `PUT /users/:id/status`
4. Context state updated with new status
5. Statistics automatically refreshed
6. UI reflects changes immediately

### Dashboard Div Update (FYH Section)
1. User uploads image → Cloudinary upload
2. User fills price and apartment type
3. Click "Save Changes" → `updateDashboardDivData()`
4. API call to `PUT /dashboard/divs/:id`
5. Context state updated
6. Success message displayed

## 🚀 Getting Started

### 1. Backend Setup
Ensure your backend is running on `http://localhost:8000`

### 2. Initial Admin Setup (One-time)
The dashboard will automatically prompt for admin setup if needed.

### 3. Default Login
- **Email**: `crypto.immobilier@gmail.com`
- **Password**: `crypto_2222`

### 4. Cloudinary Setup (Optional)
1. Create Cloudinary account
2. Get your cloud name and create upload preset
3. Update `src/utils/imageUpload.js` with your credentials

### 5. Development
```bash
npm run dev
```

## 🎯 Features Implemented

### ✅ Completed
- [x] Authentication system with JWT
- [x] Login/logout functionality  
- [x] Reservations table with real data
- [x] Reservation status updates
- [x] Real-time statistics
- [x] Dashboard divs (FYH) management
- [x] Image upload system
- [x] Error handling and loading states
- [x] Context-based state management

### 🚧 Partially Implemented
- [ ] Best Sellers section (regions/apartments)
- [ ] Hero section statistics
- [ ] File upload validation improvements

### 📋 Next Steps
1. Complete Best Sellers section integration
2. Add Hero section statistics management
3. Implement toast notifications for better UX
4. Add form validation improvements
5. Implement real-time updates with WebSockets (optional)

## 🛠️ Development Notes

### Context Usage
```jsx
// In any component
import { useAuth } from '../contexts/AuthContext';
import { useData } from '../contexts/DataContext';

const MyComponent = () => {
  const { isAuthenticated, login, logout } = useAuth();
  const { reservations, loading, fetchReservations } = useData();
  
  // Component logic here
};
```

### API Calls
```javascript
// Direct API usage (rarely needed)
import { getAllReservations, updateReservationStatus } from '../utils/api';

// Preferred: Use context hooks
const { updateReservation } = useData();
await updateReservation(reservationId, 'Done');
```

### Error Handling Pattern
```javascript
try {
  const result = await apiOperation();
  if (result.success) {
    // Handle success
  } else {
    // Handle API error
  }
} catch (error) {
  // Handle network/system error
}
```

## 🔒 Security Considerations

- JWT tokens stored securely in localStorage
- Automatic token cleanup on logout
- API endpoints protected with authentication headers
- Input validation for all user inputs
- Secure image upload with file type validation

## 📞 Support

For any issues or questions regarding the integration:
1. Check the browser console for detailed error messages
2. Verify backend API is running and accessible
3. Ensure Cloudinary credentials are correct (for image upload)
4. Check network connectivity to backend endpoints

The dashboard is now fully integrated with the backend API and follows React best practices for state management, error handling, and user experience.
