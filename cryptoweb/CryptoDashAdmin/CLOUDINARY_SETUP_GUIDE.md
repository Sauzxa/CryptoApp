# Cloudinary Setup Guide for Crypto Immobilier

This guide will help you set up your own Cloudinary account and configure your application to use it instead of the demo account.

## 📋 Prerequisites

- A free Cloudinary account (signup at [cloudinary.com](https://cloudinary.com))
- Access to your project's backend and frontend code

## 🚀 Step-by-Step Setup

### 1. Create Cloudinary Account & Get Credentials

1. **Sign up** at [cloudinary.com](https://cloudinary.com)
2. **Verify your email** and complete account setup
3. **Access your dashboard** and note down:
   - **Cloud Name**: `your-cloud-name` (visible in dashboard URL)
   - **API Key**: `123456789012345` (found in dashboard)
   - **API Secret**: `your-secret-key` (found in dashboard - keep this private!)

### 2. Create Upload Preset

1. Go to **Settings** → **Upload** in your Cloudinary dashboard
2. Scroll to **Upload presets** section
3. Click **Add upload preset**
4. Configure the preset:
   ```
   Preset name: crypto-immobilier-preset
   Signing Mode: Unsigned
   Folder: crypto-immobilier
   Resource type: Image
   Access mode: Public
   ```
5. **Save** the preset

### 3. Configure Backend Environment Variables

Create a `.env` file in your `Crypto-immobilier-Back` directory:

```bash
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-actual-cloud-name
CLOUDINARY_API_KEY=your-actual-api-key
CLOUDINARY_API_SECRET=your-actual-api-secret

# Other environment variables
DATABASE_URL=your-database-url
JWT_SECRET=your-jwt-secret
PORT=5000
NODE_ENV=development
```

⚠️ **Important**: Replace the placeholder values with your actual Cloudinary credentials!

### 4. Update Frontend Configuration

Create a `.env` file in `Crypto-immobilier-Dashboard/` with:

```bash
# API Configuration
VITE_API_BASE_URL=http://localhost:8000/api

# Cloudinary Configuration (Frontend-Safe Only!)
VITE_CLOUDINARY_CLOUD_NAME=your-actual-cloud-name
VITE_CLOUDINARY_UPLOAD_PRESET=crypto-immobilier-preset

# App Configuration
VITE_APP_NAME=Crypto Immobilier Dashboard
VITE_APP_VERSION=1.0.0
VITE_NODE_ENV=development
```

⚠️ **SECURITY WARNING**: 
- **NEVER** put `CLOUDINARY_API_KEY` or `CLOUDINARY_API_SECRET` in frontend `.env`
- Only `CLOUD_NAME` and `UPLOAD_PRESET` are safe for frontend
- API secrets belong only in backend `.env`

### 5. Folder Structure

Your images will be automatically organized in Cloudinary folders:

```
crypto-immobilier/
├── hero-images/        # Hero/banner images
├── properties/         # Property/apartment images
├── regions/           # Region/location images
├── sellers/           # Seller/agent images
├── branding/          # Logos and branding images
└── general/           # Other images
```

## 🧪 Testing Your Setup

### Test Upload Functionality

1. **Start your development servers**:
   ```bash
   # Backend
   cd Crypto-immobilier-Back
   npm run dev

   # Frontend Dashboard
   cd Crypto-immobilier-Dashboard
   npm run dev
   ```

2. **Test image upload** in your dashboard
3. **Check Cloudinary dashboard** to see uploaded images
4. **Verify folder organization** in your Cloudinary media library

### Verification Checklist

- [ ] ✅ Cloudinary account created
- [ ] ✅ Upload preset configured
- [ ] ✅ Backend .env file updated with real credentials
- [ ] ✅ Frontend configuration updated
- [ ] ✅ Test upload successful
- [ ] ✅ Images appear in correct folders

## 🔧 Advanced Configuration

### Custom Folder Structure

To use specific folders for different image types:

```javascript
import { uploadImageToFolder } from './utils/imageUpload.js';

// Upload to specific folder
const url = await uploadImageToFolder(file, 'properties/apartments');
```

### Image Transformations

Add transformations in your upload preset or via URL:

```javascript
// Example: Auto-optimized images
const optimizedUrl = originalUrl.replace('/upload/', '/upload/f_auto,q_auto/');
```

## 🚨 Security Notes

### Frontend vs Backend Environment Variables

**✅ SAFE for Frontend (.env in Dashboard):**
```bash
VITE_CLOUDINARY_CLOUD_NAME=your-cloud-name
VITE_CLOUDINARY_UPLOAD_PRESET=your-preset-name
VITE_API_BASE_URL=http://localhost:8000/api
```

**❌ NEVER in Frontend (.env in Backend ONLY):**
```bash
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### Best Practices:
1. **Never commit `.env` files** to version control
2. **Keep API Secret private** - backend only!
3. **Use unsigned presets** for frontend uploads
4. **Set folder permissions** appropriately in Cloudinary
5. **Use VITE_ prefix** for all frontend environment variables

## 📞 Support

If you encounter issues:
1. Check Cloudinary dashboard for error logs
2. Verify all credentials are correct
3. Ensure upload preset is set to "Unsigned"
4. Check browser console for upload errors

## 🔄 Migration from Demo

Your app currently uses demo URLs like:
```
https://res.cloudinary.com/demo/image/upload/...
```

After setup, your URLs will look like:
```
https://res.cloudinary.com/your-cloud-name/image/upload/...
```

The transition should be seamless once you update the configuration!
