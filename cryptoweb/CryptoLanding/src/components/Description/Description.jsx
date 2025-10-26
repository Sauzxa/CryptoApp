import React, { useState } from 'react';
import { useDescription } from '../../hooks/useDescription';
import { useLanguage } from '../../contexts/LanguageContext';
import Apartment1 from '../../assets/images/apartments/appartement1.png';

const Description = () => {
  const { descriptionContent, loading, error } = useDescription();
  const { t } = useLanguage();
  const [hoveredCard, setHoveredCard] = useState(null);

  if (loading) {
    return (
      <div className="min-h-screen bg-light-secondary dark:bg-dark-secondary flex items-center justify-center transition-colors duration-300 ease-in-out">
        <div className="text-gray-600 dark:text-gray-400 font-inter text-lg">{t('description.loading')}</div>
      </div>
    );
  }
//
  if (error) {
    console.error('Description content error:', error);
    // Still render with default content if there's an error
  }

  return (
    <section className="py-16 bg-white dark:bg-dark-primary transition-colors duration-300 ease-in-out">
      <div className="max-w-7xl mx-auto px-6 sm:px-8 lg:px-12">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          
          {/* Left side - Text content */}
          <div className="space-y-6">
            <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-gray-900 dark:text-white font-inter leading-tight transition-colors duration-300 ease-in-out">
              {t('description.title')}
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-300 font-inter leading-relaxed transition-colors duration-300 ease-in-out">
              {t('description.subtitle')}
            </p>
          </div>

          {/* Right side - Apartment cards with z-index layering */}
          <div className="relative h-[400px] md:h-[500px]">
            {descriptionContent.apartments.map((apartment, index) => {
              const isHovered = hoveredCard === apartment.id;
              const isOtherHovered = hoveredCard !== null && hoveredCard !== apartment.id;
              
              return (
                <div
                  key={apartment.id}
                  className="absolute bg-white dark:bg-gray-800 rounded-2xl shadow-xl overflow-hidden border border-gray-100 dark:border-gray-700 transition-all duration-300 ease-out cursor-pointer"
                  style={{
                    zIndex: isHovered ? 100 : apartment.zIndex,
                    width: isHovered ? '320px' : '280px',
                    height: isHovered ? '360px' : '320px',
                    // Position each card with slight offsets for layering effect
                    top: isHovered ? `${index * 40 - 20}px` : `${index * 40}px`,
                    right: isHovered ? `${index * 30 - 20}px` : `${index * 30}px`,
                    transform: `rotate(${isHovered ? 0 : (index - 1) * 3}deg) scale(${isHovered ? 1.1 : 1})`,
                    opacity: isOtherHovered ? 0.4 : 1,
                    filter: isOtherHovered ? 'blur(2px)' : 'none',
                  }}
                  onMouseEnter={() => setHoveredCard(apartment.id)}
                  onMouseLeave={() => setHoveredCard(null)}
                >
                  {/* Apartment Image */}
                  <div className={`${isHovered ? 'h-64' : 'h-56'} bg-gray-200 overflow-hidden transition-all duration-300`}>
                    <img
                      src={apartment.image}
                      alt={`Apartment ${apartment.id}`}
                      className={`w-full h-full object-cover transition-transform duration-300 ${isHovered ? 'scale-110' : 'scale-100'}`}
                      onError={(e) => {
                        e.target.src = Apartment1;
                      }}
                    />
                  </div>

                  {/* Apartment Details */}
                  <div className="p-4">
                    <div className={`${isHovered ? 'text-3xl' : 'text-2xl'} font-bold text-gray-900 dark:text-white font-inter transition-all duration-300`}>
                      {apartment.price}
                    </div>
                    <div className={`${isHovered ? 'text-base' : 'text-sm'} text-gray-600 dark:text-gray-300 font-inter font-medium transition-all duration-300`}>
                      {t(`description.apartments.period${apartment.id}`)}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

        </div>
      </div>
    </section>
  );
};

export default Description;
