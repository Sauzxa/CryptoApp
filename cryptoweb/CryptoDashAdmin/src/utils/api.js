/**
 * API utility functions for Crypto Immobilier Backend
 * Utilise URLs relatives en production, absolues en développement
 */

const isDevelopment = import.meta.env.NODE_ENV === 'development';
const BASE_URL = isDevelopment ? (import.meta.env.VITE_API_URL || 'http://localhost:8000/api') : '/api';

/**
 * Generic API call function with automatic token handling
 * @param {string} method - HTTP method (GET, POST, PUT, DELETE)
 * @param {string} endpoint - API endpoint path
 * @param {Object} data - Request body data
 * @param {boolean} requiresAuth - Whether the endpoint requires authentication
 * @returns {Promise<Object>} API response
 */
export const apiCall = async (method, endpoint, data = null, requiresAuth = true) => {
  try {
    const token = localStorage.getItem('authToken');
    
    const config = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(requiresAuth && token && { 'Authorization': `Bearer ${token}` })
      },
      ...(data && { body: JSON.stringify(data) })
    };
    
    const response = await fetch(`${BASE_URL}${endpoint}`, config);
    const result = await response.json();
    
    // Handle authentication errors
    if (response.status === 401) {
      localStorage.removeItem('authToken');
      throw new Error('Authentication failed. Please login again.');
    }
    
    return result;
  } catch (error) {
    console.error('API call failed:', error);
    throw error;
  }
};

// =============================================================================
//                            AUTHENTICATION API
// =============================================================================

/**
 * Initialize admin account (one-time setup)
 */
export const setupAdmin = async (email, password) => {
  return apiCall('POST', '/auth/setup', { email, password }, false);
};

/**
 * Admin login
 */
export const loginAdmin = async (email, password) => {
  const result = await apiCall('POST', '/auth/login', { email, password }, false);
  
  if (result.success && result.data.token) {
    localStorage.setItem('authToken', result.data.token);
  }
  
  return result;
};

/**
 * Admin logout
 */
export const logoutAdmin = async () => {
  const result = await apiCall('POST', '/auth/logout');
  localStorage.removeItem('authToken');
  return result;
};

/**
 * Check if user is authenticated
 */
export const isAuthenticated = () => {
  return localStorage.getItem('authToken') !== null;
};

// =============================================================================
//                            RESERVATIONS API
// =============================================================================

/**
 * Create new reservation
 */
export const createReservation = async (reservationData) => {
  return apiCall('POST', '/users', reservationData);
};

/**
 * Get all reservations
 */
export const getAllReservations = async () => {
  return apiCall('GET', '/users');
};

/**
 * Update reservation status
 */
export const updateReservationStatus = async (reservationId, status) => {
  return apiCall('PUT', `/users/${reservationId}/status`, { status });
};

/**
 * Get total reservations count
 */
export const getTotalReservationsCount = async () => {
  return apiCall('GET', '/users/count');
};

/**
 * Get completed reservations count
 */
export const getCompletedReservationsCount = async () => {
  return apiCall('GET', '/users/count/done');
};

/**
 * Get pending reservations count
 */
export const getPendingReservationsCount = async () => {
  return apiCall('GET', '/users/count/pending');
};

/**
 * Delete a reservation by ID
 */
export const deleteReservation = async (reservationId) => {
  return apiCall('DELETE', `/users/${reservationId}`);
};

// =============================================================================
//                            DASHBOARD FYH API
// =============================================================================

/**
 * Create or update dashboard div
 */
export const createOrUpdateDashboardDiv = async (divData) => {
  return apiCall('POST', '/dashboard/divs', divData);
};

/**
 * Update specific dashboard div (upsert - creates if doesn't exist)
 */
export const updateDashboardDiv = async (divId, divData) => {
  // Use POST endpoint with upsert functionality and include the ID in the data
  const upsertData = { id: divId, ...divData };
  return apiCall('POST', '/dashboard/divs', upsertData);
};

/**
 * Get all dashboard divs
 */
export const getAllDashboardDivs = async () => {
  return apiCall('GET', '/dashboard/divs');
};

/**
 * Get specific dashboard div
 */
export const getDashboardDiv = async (divId) => {
  return apiCall('GET', `/dashboard/divs/${divId}`);
};

// =============================================================================
//                            BEST SELLERS API
// =============================================================================

// Region Management
export const createRegion = async (name) => {
  return apiCall('POST', '/bestsellers/regions', { name });
};

export const getAllRegions = async () => {
  return apiCall('GET', '/bestsellers/regions');
};

export const deleteRegion = async (regionId) => {
  return apiCall('DELETE', `/bestsellers/regions/${regionId}`);
};

// Apartment Management
export const addApartmentToRegion = async (regionId, apartmentData) => {
  return apiCall('POST', `/bestsellers/regions/${regionId}/apartments`, apartmentData);
};

export const updateApartment = async (regionId, apartmentId, apartmentData) => {
  return apiCall('PUT', `/bestsellers/regions/${regionId}/apartments/${apartmentId}`, apartmentData);
};

export const deleteApartment = async (regionId, apartmentId) => {
  return apiCall('DELETE', `/bestsellers/regions/${regionId}/apartments/${apartmentId}`);
};

// Type Management
export const addTypeToApartment = async (regionId, apartmentId, typeName) => {
  return apiCall('POST', `/bestsellers/regions/${regionId}/apartments/${apartmentId}/types`, { name: typeName });
};

export const updateType = async (regionId, apartmentId, typeId, typeName) => {
  return apiCall('PUT', `/bestsellers/regions/${regionId}/apartments/${apartmentId}/types/${typeId}`, { name: typeName });
};

export const deleteType = async (regionId, apartmentId, typeId) => {
  return apiCall('DELETE', `/bestsellers/regions/${regionId}/apartments/${apartmentId}/types/${typeId}`);
};

// =============================================================================
//                            APARTMENT TYPES API
// =============================================================================

/**
 * Create new apartment type
 */
export const createApartmentType = async (name) => {
  return apiCall('POST', '/apartment-types', { name });
};

/**
 * Get all apartment types
 */
export const getAllApartmentTypes = async () => {
  return apiCall('GET', '/apartment-types');
};

/**
 * Get apartment type by ID
 */
export const getApartmentType = async (typeId) => {
  return apiCall('GET', `/apartment-types/${typeId}`);
};

/**
 * Update apartment type
 */
export const updateApartmentTypeById = async (typeId, name) => {
  return apiCall('PUT', `/apartment-types/${typeId}`, { name });
};

/**
 * Delete apartment type
 */
export const deleteApartmentTypeById = async (typeId) => {
  return apiCall('DELETE', `/apartment-types/${typeId}`);
};

// =============================================================================
//                            HERO SECTION NUMBERS FUNCTIONS
// =============================================================================

/**
 * Get hero section numbers
 */
export const getHeroSectionNumbers = async () => {
  return apiCall('GET', '/hero-section-numbers');
};

/**
 * Update hero section numbers
 */
export const updateHeroSectionNumbers = async (numbers) => {
  return apiCall('PUT', '/hero-section-numbers', numbers);
};

// =============================================================================
//                            UTILITY FUNCTIONS
// =============================================================================

/**
 * Handle API errors consistently
 */
export const handleApiError = (error) => {
  if (error.message === 'Authentication failed. Please login again.') {
    // Redirect to login or show auth modal
    return { type: 'AUTH_ERROR', message: error.message };
  }
  
  return { type: 'API_ERROR', message: error.message || 'An unexpected error occurred' };
};

/**
 * Get auth token from localStorage
 */
export const getAuthToken = () => {
  return localStorage.getItem('authToken');
};

/**
 * Set auth token in localStorage
 */
export const setAuthToken = (token) => {
  localStorage.setItem('authToken', token);
};

/**
 * Remove auth token from localStorage
 */
export const removeAuthToken = () => {
  localStorage.removeItem('authToken');
};
