import React, { useState } from 'react';

const RegionSelector = ({ regions, selectedRegion, onRegionChange }) => {
  const [isOpen, setIsOpen] = useState(false);

  const handleRegionSelect = (region) => {
    onRegionChange(region);
    setIsOpen(false);
  };

  return (
    <div className="relative z-50">
      {/* Dropdown Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="bg-red-500 hover:bg-red-600 text-white px-6 py-3 rounded-lg font-inter font-medium text-lg flex items-center gap-3 min-w-[180px] justify-between transition-colors"
      >
        <span>{selectedRegion.name}</span>
        <svg 
          className={`w-5 h-5 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <>
          {/* Backdrop */}
          <div 
            className="fixed inset-0 z-[9998]" 
            onClick={() => setIsOpen(false)}
          />
          
          {/* Dropdown Content */}
          <div className="absolute top-full left-0 mt-2 w-full bg-white border border-gray-200 rounded-lg shadow-xl z-[9999] overflow-hidden">
            {regions.map((region) => (
              <button
                key={region.id}
                onClick={() => handleRegionSelect(region)}
                className={`w-full px-6 py-3 text-left font-inter text-lg hover:bg-gray-50 transition-colors ${
                  selectedRegion.id === region.id 
                    ? 'bg-red-50 text-red-600 font-medium' 
                    : 'text-gray-700'
                }`}
              >
                {region.name}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default RegionSelector;
