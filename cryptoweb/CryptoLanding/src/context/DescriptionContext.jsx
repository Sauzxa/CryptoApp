import React, { createContext, useState, useEffect } from 'react';
import { DEFAULT_DESCRIPTION_CONTENT } from '../constants';
import { dashboardAPI } from '../utils/api';

const DescriptionContext = createContext();

export const DescriptionProvider = ({ children }) => {
  const [descriptionContent, setDescriptionContent] = useState(DEFAULT_DESCRIPTION_CONTENT);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Function to fetch description content from dashboard API
  const fetchDescriptionContent = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await dashboardAPI.getDashboardDivs();
      if (response.success && response.data && response.data.length > 0) {
        // Transform dashboard divs to description content format
        const apartments = response.data.map((dashboardDiv, index) => ({
          id: dashboardDiv.id || (index + 1),
          price: `DZD ${dashboardDiv.price?.toLocaleString() || '0'}`,
          period: dashboardDiv.apartment || `F${index + 2} | Per Month`,
          image: dashboardDiv.photoUrl || DEFAULT_DESCRIPTION_CONTENT.apartments[index]?.image,
          zIndex: 30 - (index * 10) // Decreasing z-index: 30, 20, 10
        }));

        const transformedContent = {
          title: DEFAULT_DESCRIPTION_CONTENT.title, // Keep default title
          description: DEFAULT_DESCRIPTION_CONTENT.description, // Keep default description
          apartments: apartments.length >= 3 ? apartments.slice(0, 3) : [
            ...apartments,
            ...DEFAULT_DESCRIPTION_CONTENT.apartments.slice(apartments.length)
          ]
        };
        setDescriptionContent(transformedContent);
      } else {
        // Use default content if no data available
        setDescriptionContent(DEFAULT_DESCRIPTION_CONTENT);
      }
    } catch (err) {
      setError(err.message);
      console.error('Error fetching description content:', err);
      // Keep default content on error
      setDescriptionContent(DEFAULT_DESCRIPTION_CONTENT);
    } finally {
      setLoading(false);
    }
  };

  // Function to update description content (for admin dashboard)
  const updateDescriptionContent = async (newContent) => {
    setLoading(true);
    setError(null);
    
    try {
      const data = await descriptionAPI.updateDescriptionContent(newContent);
      setDescriptionContent(data);
      return data;
    } catch (err) {
      setError(err.message);
      console.error('Error updating description content:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Fetch description content on component mount
    fetchDescriptionContent();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const value = {
    descriptionContent,
    loading,
    error,
    fetchDescriptionContent,
    updateDescriptionContent,
    setDescriptionContent
  };

  return (
    <DescriptionContext.Provider value={value}>
      {children}
    </DescriptionContext.Provider>
  );
};

export default DescriptionContext;
