import React from 'react';
import { useHero } from '../../hooks/useHero';
import { useLanguage } from '../../contexts/LanguageContext';

 const Hero = () => {
  const { heroContent, loading, error } = useHero();
  const { t } = useLanguage();

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-gray-600 font-inter text-lg">{t('hero.loading')}</div>
      </div>
    );
  }

  if (error) {
    console.error('Hero content error:', error);
    // Still render with default content if there's an error
  }

  return (
    <section 
      className="relative h-[40vh] md:h-[45vh] bg-cover bg-center bg-no-repeat"
      style={{
        backgroundImage: `url('${heroContent.backgroundImage}')`
      }}
    >
      {/* Overlay for better text readability */}
      <div className="absolute inset-0 bg-black bg-opacity-30"></div>
      
      {/* Hero Content */}
      <div className="relative z-10 h-full flex items-center justify-center px-6 sm:px-8 lg:px-12">
        <div className="w-full max-w-7xl mx-auto mt-8 md:mt-12">
          <div className="flex flex-col md:flex-row items-center justify-center text-center gap-8 md:gap-12 lg:gap-16">
            {/* Main Hero Title */}
            <div className="flex-1">
              <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold text-white font-inter leading-tight tracking-tight">
                {t('hero.title')}
              </h1>
            </div>
            
            {/* Statistics */}
            {heroContent.statistics.map((stat, index) => {
              const statKeys = ['propertiesListed', 'happyClients', 'averageDays'];
              return (
                <div key={index} className="flex-1 text-center">
                  <div className="text-2xl md:text-3xl lg:text-4xl font-bold text-white font-inter mb-1 tracking-tight">
                    {stat.number}
                  </div>
                  <div className="text-sm md:text-base lg:text-lg text-white font-inter font-medium opacity-90 leading-relaxed">
                    {t(`hero.statistics.${statKeys[index]}`)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
      
      {/* Scroll indicator - clickable button */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-30">
        <button 
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('Button clicked!'); // Debug log
            const aboutSection = document.getElementById('about');
            if (aboutSection) {
              const navHeight = 80; // Height of the navbar
              const elementPosition = aboutSection.offsetTop - navHeight;
              
              window.scrollTo({
                top: elementPosition,
                behavior: 'smooth'
              });
            }
          }}
          className="animate-bounce hover:scale-110 transition-transform duration-300 cursor-pointer focus:outline-none focus:ring-2 focus:ring-white focus:ring-opacity-50 rounded-full p-4 bg-black bg-opacity-20 hover:bg-opacity-30"
          aria-label={t('hero.scrollToAbout')}
          type="button"
        >
          <svg 
            className="w-6 h-6 text-white opacity-80 hover:opacity-100 transition-opacity duration-300 pointer-events-none" 
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path 
              strokeLinecap="round" 
              strokeLinejoin="round" 
              strokeWidth={2} 
              d="M19 14l-7 7m0 0l-7-7m7 7V3" 
            />
          </svg>
        </button>
      </div>
    </section>
  );
};

export default Hero;
