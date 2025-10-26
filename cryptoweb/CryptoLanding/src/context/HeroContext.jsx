import React, { createContext, useState, useEffect } from 'react';
import { DEFAULT_HERO_CONTENT } from '../constants';
import { heroAPI, heroSectionNumbersAPI } from '../utils/api';

const HeroContext = createContext();

export const HeroProvider = ({ children }) => {
  const [heroContent, setHeroContent] = useState(DEFAULT_HERO_CONTENT);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Function to fetch hero section numbers from backend
  const fetchHeroSectionNumbers = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await heroSectionNumbersAPI.getHeroSectionNumbers();
      if (response.success && response.data) {
        // Update hero content with dynamic numbers
        setHeroContent(prevContent => ({
          ...prevContent,
          statistics: [
            {
              number: response.data.propertiesListed,
              label: "Properties Listed"
            },
            {
              number: response.data.happyClients,
              label: "Happy Clients Served"
            },
            {
              number: response.data.daysToClose,
              label: "Days to Close a Deal"
            }
          ]
        }));
      }
    } catch (err) {
      setError(err.message);
      console.error('Error fetching hero section numbers:', err);
      // Keep default content on error
      setHeroContent(DEFAULT_HERO_CONTENT);
    } finally {
      setLoading(false);
    }
  };

  // Function to fetch hero content from backend (kept for compatibility)
  const fetchHeroContent = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const data = await heroAPI.getHeroContent();
      setHeroContent(data);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching hero content:', err);
      // Keep default content on error
      setHeroContent(DEFAULT_HERO_CONTENT);
    } finally {
      setLoading(false);
    }
  };

  // Function to update hero content (for admin dashboard)
  const updateHeroContent = async (newContent) => {
    setLoading(true);
    setError(null);
    
    try {
      const data = await heroAPI.updateHeroContent(newContent);
      setHeroContent(data);
      return data;
    } catch (err) {
      setError(err.message);
      console.error('Error updating hero content:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Fetch hero section numbers on component mount
    fetchHeroSectionNumbers();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const value = {
    heroContent,
    loading,
    error,
    fetchHeroContent,
    fetchHeroSectionNumbers,
    updateHeroContent,
    setHeroContent
  };

  return (
    <HeroContext.Provider value={value}>
      {children}
    </HeroContext.Provider>
  );
};

export default HeroContext;
