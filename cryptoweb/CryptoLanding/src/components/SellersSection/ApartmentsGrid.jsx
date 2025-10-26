import React, { useState, useEffect } from 'react';
import Apartment1 from '../../assets/images/apartments/appartement1.png';

const ApartmentsGrid = ({ apartments, currentIndex }) => {
  const [hoveredApartment, setHoveredApartment] = useState(null);
  const [maxVisible, setMaxVisible] = useState(4);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [prevCurrentIndex, setPrevCurrentIndex] = useState(currentIndex);

  // Update maxVisible based on screen size
  useEffect(() => {
    const updateMaxVisible = () => {
      let newMaxVisible;
      if (window.innerWidth >= 1024) newMaxVisible = 4; // lg screens
      else if (window.innerWidth >= 768) newMaxVisible = 3; // md screens
      else if (window.innerWidth >= 640) newMaxVisible = 2; // sm screens
      else newMaxVisible = 1; // mobile screens
      
      setMaxVisible(newMaxVisible);
    };

    updateMaxVisible();
    window.addEventListener('resize', updateMaxVisible);
    return () => window.removeEventListener('resize', updateMaxVisible);
  }, []);

  // Handle smooth transitions when currentIndex changes
  useEffect(() => {
    if (currentIndex !== prevCurrentIndex) {
      setIsTransitioning(true);
      setPrevCurrentIndex(currentIndex);
      
      // Reset transition state after animation completes
      const timer = setTimeout(() => {
        setIsTransitioning(false);
      }, 600); // Match the fadeIn animation duration
      
      return () => clearTimeout(timer);
    }
  }, [currentIndex, prevCurrentIndex]);

  if (!apartments || apartments.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500 dark:text-gray-400 font-inter text-lg transition-colors duration-300 ease-in-out">
          No apartments available in this region
        </p>
      </div>
    );
  }

  // Create a sliding window of apartments like a scrollbar
  const getVisibleApartments = () => {
    const totalApartments = apartments.length;
    
    // Simple scrollbar logic: start from currentIndex and show maxVisible apartments
    const startIndex = currentIndex;
    const endIndex = Math.min(startIndex + maxVisible, totalApartments);
    
    return apartments.slice(startIndex, endIndex);
  };

  const visibleApartments = getVisibleApartments();

  return (
    <div className="overflow-hidden">
      <div 
        className={`flex gap-2 sm:gap-3 md:gap-4 lg:gap-6 justify-start transition-all duration-500 ease-in-out transform ${
          isTransitioning ? 'animate-slideIn' : ''
        }`}
      >
        {visibleApartments.map((apartment, index) => (
          <div
            key={`${apartment.id}-${currentIndex}`}
            className={`relative group cursor-pointer overflow-hidden rounded-2xl bg-white dark:bg-gray-800 shadow-lg transition-all duration-500 hover:scale-[1.02] hover:shadow-xl flex-shrink-0 w-full sm:w-64 md:w-72 lg:w-80 ${
              isTransitioning ? 'opacity-0 animate-fadeIn' : 'opacity-100'
            }`}
            style={{
              animationDelay: isTransitioning ? `${index * 120}ms` : '0ms',
              animationFillMode: 'forwards'
            }}
            onMouseEnter={() => setHoveredApartment(apartment.id)}
            onMouseLeave={() => setHoveredApartment(null)}
          >
          {/* Apartment Image */}
          <div className="relative aspect-[4/3] overflow-hidden rounded-2xl">
            <img
              src={apartment.image}
              alt={apartment.name || 'Apartment'}
              className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
              onError={(e) => {
                e.target.src = Apartment1;
              }}
            />
            
            {/* Region Label - Top Right */}
            <div className="absolute top-4 right-4 bg-white dark:bg-dark-primary bg-opacity-95 dark:bg-opacity-95 backdrop-blur-sm px-3 py-1.5 rounded-full shadow-lg transition-colors duration-300 ease-in-out">
              <span className="text-xs font-inter font-bold text-gray-800 dark:text-gray-100 uppercase tracking-wide">
                {apartment.name ? apartment.name.split(' ')[0] : 'Apartment'}
              </span>
            </div>

            {/* Hover Overlay */}
            <div className={`absolute inset-0 bg-black transition-opacity duration-300 flex items-center justify-center ${
              hoveredApartment === apartment.id ? 'bg-opacity-70' : 'bg-opacity-0 pointer-events-none'
            }`}>
              <div className={`text-center text-white p-6 transition-all duration-300 ${
                hoveredApartment === apartment.id ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
              }`}>
                <h3 className="text-lg md:text-xl font-inter font-bold mb-3 leading-tight">
                  {apartment.name || 'Apartment'}
                </h3>
                <div className="flex items-center justify-center gap-3">
                  <div 
                    className={`w-3 h-3 rounded-full ${
                      (apartment.availability || apartment.status) === 'Available' 
                        ? 'bg-green-400 animate-pulse' 
                        : 'bg-red-400'
                    }`}
                  />
                  <span className="text-sm md:text-base font-inter font-medium">
                    {apartment.availability || apartment.status || 'Available'}
                  </span>
                </div>
              </div>
            </div>
          </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ApartmentsGrid;
