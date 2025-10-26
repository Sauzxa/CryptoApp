/**
 * Simple Cloudinary Image Upload Utility
 * 
 * SECURITY NOTE: 
 * - Only CLOUD_NAME and UPLOAD_PRESET are safe to expose in frontend
 * - API_KEY and API_SECRET should NEVER be in frontend code
 */

// Cloudinary configuration from environment variables or fallback to demo
const CLOUDINARY_CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || 'demo';
const CLOUDINARY_UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || 'ml_default';

const CLOUDINARY_UPLOAD_URL = `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`;

const isDemo = CLOUDINARY_CLOUD_NAME === 'demo';

// Debug configuration
console.log('🔧 Cloudinary Configuration:');
console.log('Cloud Name:', CLOUDINARY_CLOUD_NAME);
console.log('Upload Preset:', CLOUDINARY_UPLOAD_PRESET);
console.log('Upload URL:', CLOUDINARY_UPLOAD_URL);
console.log('Demo Mode:', isDemo);

// Validate configuration
if (isDemo) {
  console.warn('⚠️ Using Cloudinary demo account. Images may be deleted after some time.');
  console.warn('📖 See CLOUDINARY_SETUP_GUIDE.md for setup instructions.');
} else if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_UPLOAD_PRESET) {
  console.error('⚠️ Cloudinary not configured. Check your .env file:');
  console.error('VITE_CLOUDINARY_CLOUD_NAME:', CLOUDINARY_CLOUD_NAME);
  console.error('VITE_CLOUDINARY_UPLOAD_PRESET:', CLOUDINARY_UPLOAD_PRESET);
}

/**
 * Simple file validation
 * @param {File} file - The file to validate
 */
const validateFile = (file) => {
  if (!file) throw new Error('No file provided');
  if (!file.type.startsWith('image/')) throw new Error('Please select a valid image file');
  
  const maxSize = 5 * 1024 * 1024; // 5MB
  if (file.size > maxSize) throw new Error('File size must be less than 5MB');
};

/**
 * Get folder name based on file name
 * @param {string} fileName - The file name
 * @returns {string} Folder name
 */
const getFolderName = (fileName) => {
  const name = fileName.toLowerCase();
  
  if (name.includes('hero') || name.includes('banner')) return 'hero-images';
  if (name.includes('apartment') || name.includes('property')) return 'properties';
  if (name.includes('region') || name.includes('location')) return 'regions';
  if (name.includes('seller') || name.includes('agent')) return 'sellers';
  if (name.includes('logo') || name.includes('brand')) return 'branding';
  
  return 'general';
};

/**
 * Upload image to Cloudinary
 * @param {File} file - The image file to upload
 * @param {string} customFolder - Optional custom folder name
 * @returns {Promise<string>} The Cloudinary URL
 */
export const uploadImage = async (file, customFolder = null) => {
  try {
    // Validate file
    validateFile(file);

    // Check if Cloudinary is configured (demo mode is OK)
    if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_UPLOAD_PRESET) {
      console.warn('Cloudinary not configured, returning mock URL');
      // Return a mock URL for development
      return `https://res.cloudinary.com/demo/image/upload/v${Date.now()}/sample.jpg`;
    }

    // Special handling for demo mode
    if (isDemo) {
      console.warn('📤 Uploading to Cloudinary demo account...');
    }

    // Prepare form data
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', CLOUDINARY_UPLOAD_PRESET);
    
    // Set folder (skip folder for demo mode)
    const folder = customFolder || getFolderName(file.name);
    if (!isDemo) {
      formData.append('folder', `crypto-immobilier/${folder}`);
    }

    // Upload to Cloudinary
    console.log('📤 Uploading to Cloudinary...');
    console.log('URL:', CLOUDINARY_UPLOAD_URL);
    console.log('Folder:', folder);
    
    const response = await fetch(CLOUDINARY_UPLOAD_URL, {
      method: 'POST',
      body: formData,
    });

    console.log('📥 Response Status:', response.status, response.statusText);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Upload Error Response:', errorText);
      
      // Handle specific Cloudinary errors
      if (response.status === 400) {
        // Try to parse error as JSON
        try {
          const errorJson = JSON.parse(errorText);
          console.error('❌ Parsed Error:', errorJson);
          
          // Handle common Cloudinary errors
          if (errorJson.error?.message?.includes('Upload preset not found')) {
            throw new Error('Upload preset not found. Please check your Cloudinary configuration in the .env file.');
          } else if (errorJson.error?.message?.includes('Invalid')) {
            throw new Error(`Invalid upload: ${errorJson.error.message}`);
          } else {
            throw new Error(`Upload failed: ${errorJson.error?.message || response.statusText}`);
          }
        } catch {
          // If not JSON, show the raw error
          if (errorText.includes('Upload preset not found')) {
            throw new Error('Upload preset not found. Please check your Cloudinary configuration in the .env file.');
          }
          throw new Error(`Upload failed (${response.status}): ${errorText || response.statusText}`);
        }
      } else {
        throw new Error(`Upload failed (${response.status}): ${errorText || response.statusText}`);
      }
    }

    const data = await response.json();
    console.log('✅ Upload Success:', data);
    
    if (data.error) {
      console.error('❌ Cloudinary Error:', data.error);
      throw new Error(data.error.message);
    }

    return data.secure_url;

  } catch (error) {
    console.error('Image upload failed:', error);
    throw error;
  }
};

/**
 * Create preview URL for a file
 * @param {File} file - The image file
 * @returns {string|null} Preview URL
 */
export const createPreview = (file) => {
  if (!file) return null;
  return URL.createObjectURL(file);
};

/**
 * Clean up preview URL
 * @param {string} url - The preview URL to clean up
 */
export const cleanupPreview = (url) => {
  if (url && url.startsWith('blob:')) {
    URL.revokeObjectURL(url);
  }
};

/**
 * Validate image file (simple sync version)
 * @param {File} file - The file to validate
 * @returns {Object} Validation result
 */
export const validateImage = (file) => {
  try {
    validateFile(file);
    return { isValid: true, error: null };
  } catch (error) {
    return { isValid: false, error: error.message };
  }
};

/**
 * Check if Cloudinary is properly configured
 * @returns {boolean} Configuration status
 */
export const isConfigured = () => {
  return !!(CLOUDINARY_CLOUD_NAME && CLOUDINARY_UPLOAD_PRESET);
};