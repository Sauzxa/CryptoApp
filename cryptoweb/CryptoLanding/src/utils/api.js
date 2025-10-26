import { API_ENDPOINTS } from '../constants';

// Generic API call function
export const apiCall = async (endpoint, options = {}) => {
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const config = {
    ...defaultOptions,
    ...options,
    headers: {
      ...defaultOptions.headers,
      ...options.headers,
    },
  };

  try {
    const response = await fetch(endpoint, config);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('API call failed:', error);
    throw error;
  }
};

// Hero content specific API calls
export const heroAPI = {
  // Get hero content
  getHeroContent: () => {
    return apiCall(API_ENDPOINTS.HERO_CONTENT, {
      method: 'GET',
    });
  },

  // Update hero content
  updateHeroContent: (content) => {
    return apiCall(API_ENDPOINTS.HERO_CONTENT, {
      method: 'POST',
      body: JSON.stringify(content),
    });
  },
};

// Description content specific API calls
export const descriptionAPI = {
  // Get description content
  getDescriptionContent: () => {
    return apiCall(API_ENDPOINTS.DESCRIPTION_CONTENT, {
      method: 'GET',
    });
  },

  // Update description content
  updateDescriptionContent: (content) => {
    return apiCall(API_ENDPOINTS.DESCRIPTION_CONTENT, {
      method: 'POST',
      body: JSON.stringify(content),
    });
  },
};

// Hero section numbers specific API calls
export const heroSectionNumbersAPI = {
  // Get hero section numbers
  getHeroSectionNumbers: () => {
    return apiCall(API_ENDPOINTS.HERO_SECTION_NUMBERS, {
      method: 'GET',
    });
  },

  // Update hero section numbers
  updateHeroSectionNumbers: (numbers) => {
    return apiCall(API_ENDPOINTS.HERO_SECTION_NUMBERS, {
      method: 'PUT',
      body: JSON.stringify(numbers),
    });
  },
};

// Dashboard divs specific API calls
export const dashboardAPI = {
  // Get all dashboard divs
  getDashboardDivs: () => {
    return apiCall(API_ENDPOINTS.DASHBOARD_DIVS, {
      method: 'GET',
    });
  },
};

// Best sellers regions specific API calls
export const bestSellersAPI = {
  // Get all regions with apartments
  getRegions: () => {
    return apiCall(API_ENDPOINTS.BESTSELLERS_REGIONS, {
      method: 'GET',
    });
  },
};

export default {
  apiCall,
  heroAPI,
  descriptionAPI,
  heroSectionNumbersAPI,
  dashboardAPI,
  bestSellersAPI,
};
