import React, { useState, useEffect } from 'react';
import { DEFAULT_SELLERS_CONTENT } from '../../constants';
import { bestSellersAPI } from '../../utils/api';
import { useLanguage } from '../../contexts/LanguageContext';
import RegionSelector from './RegionSelector';
import ApartmentsGrid from './ApartmentsGrid';

const SellersSection = () => {
  const { t } = useLanguage();
  const [sellersData, setSellersData] = useState(DEFAULT_SELLERS_CONTENT);
  const [selectedRegion, setSelectedRegion] = useState(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch regions data from API
  useEffect(() => {
    const fetchRegions = async () => {
      try {
        setLoading(true);
        const response = await bestSellersAPI.getRegions();
        
        if (response.success && response.data && response.data.length > 0) {
          // Transform API data to match component structure
          const transformedData = {
            regions: response.data.map(region => ({
              id: region.id,
              name: region.name,
              apartments: (region.apartments || []).map(apartment => ({
                id: apartment.id,
                name: apartment.description || 'Apartment',
                image: apartment.imageUrl,
                availability: 'Available', // Default status
                types: apartment.types || []
              }))
            }))
          };
          
          setSellersData(transformedData);
          setSelectedRegion(transformedData.regions[0]); // Set first region as default
        } else {
          // Use default data if no regions found
          setSellersData(DEFAULT_SELLERS_CONTENT);
          setSelectedRegion(DEFAULT_SELLERS_CONTENT.regions[0]);
        }
      } catch (err) {
        console.error('Error fetching regions:', err);
        setError(err.message);
        // Use default data on error
        setSellersData(DEFAULT_SELLERS_CONTENT);
        setSelectedRegion(DEFAULT_SELLERS_CONTENT.regions[0]);
      } finally {
        setLoading(false);
      }
    };

    fetchRegions();
  }, []);

  const handleRegionChange = (region) => {
    setSelectedRegion(region);
    setCurrentIndex(0); // Reset to first apartment when region changes
  };

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }
  };

  const handleNext = () => {
    // For scrollbar behavior: we can move forward as long as there are more apartments beyond the current view
    // The maximum currentIndex should be such that we can still show at least one apartment
    if (selectedRegion && selectedRegion.apartments) {
      const maxIndex = selectedRegion.apartments.length - 1;
      if (currentIndex < maxIndex) {
        setCurrentIndex(currentIndex + 1);
      }
    }
  };

  // Show loading state
  if (loading) {
    return (
      <section className="py-16 bg-gray-50 dark:bg-dark-secondary transition-colors duration-300 ease-in-out relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8 lg:px-12">
          <div className="flex items-center justify-center">
            <div className="text-gray-600 dark:text-gray-400 font-inter text-lg">{t('sellers.loading')}</div>
          </div>
        </div>
      </section>
    );
  }

  // Show error state but still render with default content
  if (error) {
    console.error('Sellers section error:', error);
  }

  // Don't render if no selected region
  if (!selectedRegion) {
    return (
      <section className="py-16 bg-gray-50 dark:bg-dark-secondary transition-colors duration-300 ease-in-out relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8 lg:px-12">
          <div className="flex items-center justify-center">
            <div className="text-gray-600 dark:text-gray-400 font-inter text-lg">{t('sellers.noRegions')}</div>
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="py-16 bg-light-secondary dark:bg-dark-secondary transition-colors duration-300 ease-in-out relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8 lg:px-12">
        
        {/* Main Layout - Left: Text + Controls, Right: Apartments */}
        <div className="flex flex-col lg:flex-row gap-12 lg:gap-16 items-start">
          
          {/* Left Column - Title and Region Selector */}
          <div className="flex flex-col gap-8 lg:w-1/3">
            {/* Title */}
            <div>
              <h2 className="text-5xl md:text-6xl lg:text-7xl font-bold text-gray-900 dark:text-white font-inter leading-[0.9] tracking-tight transition-colors duration-300 ease-in-out">
                {t('sellers.title').split('\n').map((line, index) => (
                  <React.Fragment key={index}>
                    {line}
                    {index < t('sellers.title').split('\n').length - 1 && <br />}
                  </React.Fragment>
                ))}
              </h2>
            </div>

            {/* Region Selector */}
            <div>
              <RegionSelector
                regions={sellersData.regions}
                selectedRegion={selectedRegion}
                onRegionChange={handleRegionChange}
              />
            </div>
          </div>

          {/* Right Column - Apartments Grid */}
          <div className="flex-1 lg:w-2/3 overflow-x-auto">
            <ApartmentsGrid
              apartments={selectedRegion?.apartments || []}
              currentIndex={currentIndex}
            />
          </div>
        </div>

        {/* Navigation Arrows */}
        <div className="flex justify-center gap-4 mt-12">
          <button 
            onClick={handlePrevious}
            disabled={currentIndex === 0}
            className={`w-12 h-12 bg-white dark:bg-dark-primary border-2 border-gray-300 dark:border-gray-600 rounded-full flex items-center justify-center transition-all duration-300 transform ${
              currentIndex === 0 
                ? 'opacity-50 cursor-not-allowed' 
                : 'hover:bg-gray-50 dark:hover:bg-gray-800 hover:border-gray-400 dark:hover:border-gray-500 hover:scale-110 active:scale-95'
            }`}
          >
            <svg 
              className="w-6 h-6 text-gray-600 dark:text-gray-400" 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <button 
            onClick={handleNext}
            disabled={!selectedRegion || !selectedRegion.apartments || currentIndex >= selectedRegion.apartments.length - 1}
            className={`w-12 h-12 bg-white dark:bg-dark-primary border-2 border-gray-300 dark:border-gray-600 rounded-full flex items-center justify-center transition-all duration-300 transform ${
              !selectedRegion || !selectedRegion.apartments || currentIndex >= selectedRegion.apartments.length - 1
                ? 'opacity-50 cursor-not-allowed' 
                : 'hover:bg-gray-50 dark:hover:bg-gray-800 hover:border-gray-400 dark:hover:border-gray-500 hover:scale-110 active:scale-95'
            }`}
          >
            <svg 
              className="w-6 h-6 text-gray-600 dark:text-gray-400" 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

      </div>
    </section>
  );
};

export default SellersSection;
