import React, { useState, useEffect, useMemo } from 'react';
import Logo from '../../assets/images/logos/Logo.png';
import EnglishFlag from '../../assets/icons/english.png';
import FrenchFlag from '../../assets/icons/franch.png';
import { useLanguage } from '../../contexts/LanguageContext';
import { useTheme } from '../../contexts/ThemeContext';

const NavBar = () => {
  const { currentLanguage, changeLanguage, t } = useLanguage();
  const { theme, toggleTheme } = useTheme();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const isDarkMode = theme === 'dark';
  const [activeSection, setActiveSection] = useState('home');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Navigation items with their corresponding section IDs
  const navItems = useMemo(() => [
    { name: t('navbar.home'), href: '#home', id: 'home' },
    { name: t('navbar.about'), href: '#about', id: 'about' },
    { name: t('navbar.sellers'), href: '#sellers', id: 'sellers' },
    { name: t('navbar.reservation'), href: '#reservation', id: 'reservation' },
    { name: t('navbar.findUs'), href: '#footer', id: 'footer' },
  ], [t]);

  // Smooth scroll function
  const smoothScrollTo = (elementId) => {
    const element = document.getElementById(elementId);
    if (element) {
      const navHeight = 80; // Height of the navbar
      const elementPosition = element.offsetTop - navHeight;
      
      window.scrollTo({
        top: elementPosition,
        behavior: 'smooth'
      });
      
      // Close mobile menu if open
      setIsMobileMenuOpen(false);
    }
  };

  // Track active section on scroll
  useEffect(() => {
    const handleScroll = () => {
      const sections = navItems.map(item => item.id);
      const scrollPosition = window.scrollY + 150; // Increased offset for better tracking

      // Special handling for footer (if we're near the bottom)
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      const isNearBottom = window.scrollY + windowHeight >= documentHeight - 50;
      
      if (isNearBottom) {
        setActiveSection('footer');
        return;
      }

      for (let i = sections.length - 1; i >= 0; i--) {
        const section = document.getElementById(sections[i]);
        if (section && section.offsetTop <= scrollPosition) {
          setActiveSection(sections[i]);
          break;
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    handleScroll(); // Call once to set initial active section

    return () => window.removeEventListener('scroll', handleScroll);
  }, [navItems]);

  const handleLanguageChange = (lang) => {
    changeLanguage(lang);
    setIsDropdownOpen(false);
  };

  const handleThemeToggle = () => {
    toggleTheme();
    console.log(`Theme changed to: ${!isDarkMode ? 'dark' : 'light'} mode`);
  };

  return (
    <nav className="absolute top-0 left-0 right-0 z-50 bg-white/90 dark:bg-dark-primary/90 backdrop-blur-sm shadow-sm border-b border-gray-100 dark:border-gray-800 transition-colors duration-300 ease-in-out">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-20 relative">
          {/* Logo */}
          <div className="flex-shrink-0">
            <img 
              className="h-14 w-auto" 
              src={Logo} 
              alt="Crypto Immobilier Logo" 
            />
          </div>
          
          {/* Navigation Menu */}
          <div className="hidden md:block">
            <div className="ml-10 flex items-baseline space-x-8">
              {navItems.map((item) => (
                <button
                  key={item.id}
                  onClick={() => smoothScrollTo(item.id)}
                  className={`px-3 py-2 text-sm font-medium font-inter transition-all duration-300 relative group ${
                    activeSection === item.id
                      ? 'text-blue-600 dark:text-blue-400'
                      : 'text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400'
                  }`}
                >
                  {item.name}
                  {/* Active indicator */}
                  <span
                    className={`absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-blue-600 dark:bg-blue-400 transition-all duration-300 ${
                      activeSection === item.id ? 'w-full' : 'group-hover:w-full'
                    }`}
                  />
                </button>
              ))}
            </div>
          </div>
          
          {/* Right side - Language selector and toggle */}
          <div className="hidden md:flex items-center space-x-6">
            {/* Language Selector with Flag and Dropdown */}
            <div className="relative">
              <div 
                className="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 px-3 py-2 rounded-md transition-colors duration-200"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              >
                <img 
                  src={currentLanguage === 'en' ? EnglishFlag : FrenchFlag} 
                  alt={currentLanguage === 'en' ? t('navbar.english') : t('navbar.french')} 
                  className="w-6 h-4 rounded-sm"
                />
                <span className="text-sm font-medium text-gray-900 dark:text-gray-100 font-inter">
                  {currentLanguage === 'en' ? 'EN' : 'FR'}
                </span>
                <svg 
                  className={`w-4 h-4 text-gray-600 dark:text-gray-400 transition-transform duration-200 ${isDropdownOpen ? 'rotate-180' : ''}`} 
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
              
              {/* Dropdown Menu */}
              {isDropdownOpen && (
                <div className="absolute right-0 mt-2 w-32 bg-white dark:bg-dark-secondary rounded-md shadow-lg ring-1 ring-black ring-opacity-5 dark:ring-white dark:ring-opacity-5 z-50">
                  <div className="py-1">
                    <button
                      onClick={() => handleLanguageChange('en')}
                      className={`flex items-center space-x-2 w-full px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200 ${
                        currentLanguage === 'en' 
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400' 
                          : 'text-gray-700 dark:text-gray-300'
                      }`}
                    >
                      <img 
                        src={EnglishFlag} 
                        alt="English" 
                        className="w-5 h-3 rounded-sm"
                      />
                      <span className="font-inter">{t('navbar.english')}</span>
                    </button>
                    <button
                      onClick={() => handleLanguageChange('fr')}
                      className={`flex items-center space-x-2 w-full px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200 ${
                        currentLanguage === 'fr' 
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400' 
                          : 'text-gray-700 dark:text-gray-300'
                      }`}
                    >
                      <img 
                        src={FrenchFlag} 
                        alt="French" 
                        className="w-5 h-3 rounded-sm"
                      />
                      <span className="font-inter">{t('navbar.french')}</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
            
            {/* Theme Toggle with Sun/Moon Icons */}
            <div className="flex items-center">
              <button
                onClick={handleThemeToggle}
                className={`relative inline-flex items-center w-16 h-8 rounded-full transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 ${
                  isDarkMode ? 'bg-blue-600' : 'bg-gray-200'
                }`}
              >
                {/* Slider */}
                <div className={`absolute w-6 h-6 bg-white rounded-full shadow-sm transition-transform duration-300 ease-in-out flex items-center justify-center ${
                  isDarkMode ? 'translate-x-9' : 'translate-x-1'
                }`}>
                  {isDarkMode ? (
                    // Moon Icon
                    <svg className="w-4 h-4 text-blue-800" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                    </svg>
                  ) : (
                    // Sun Icon
                    <svg className="w-4 h-4 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
                    </svg>
                  )}
                </div>
                
                {/* Background Icons */}
                <div className="absolute left-2 top-2 w-4 h-4">
                  <svg className={`w-4 h-4 transition-opacity duration-300 ${!isDarkMode ? 'opacity-40' : 'opacity-0'}`} fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
                  </svg>
                </div>
                
                <div className="absolute right-2 top-2 w-4 h-4">
                  <svg className={`w-4 h-4 text-white transition-opacity duration-300 ${isDarkMode ? 'opacity-40' : 'opacity-0'}`} fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                </div>
              </button>
            </div>
          </div>
          
          {/* Mobile menu button and controls */}
          <div className="md:hidden flex items-center space-x-3">
            {/* Language Selector for Mobile */}
            <div className="relative">
              <div 
                className="flex items-center space-x-1 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 p-2 rounded-md transition-colors duration-200"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              >
                <img 
                  src={currentLanguage === 'en' ? EnglishFlag : FrenchFlag} 
                  alt={currentLanguage === 'en' ? t('navbar.english') : t('navbar.french')} 
                  className="w-5 h-3 rounded-sm"
                />
                <span className="text-xs font-medium text-gray-900 font-inter">
                  {currentLanguage === 'en' ? 'EN' : 'FR'}
                </span>
              </div>
              
              {/* Mobile Dropdown Menu */}
              {isDropdownOpen && (
                <div className="absolute right-0 mt-2 w-28 bg-white dark:bg-dark-secondary rounded-md shadow-lg ring-1 ring-black ring-opacity-5 dark:ring-white dark:ring-opacity-5 z-50">
                  <div className="py-1">
                    <button
                      onClick={() => handleLanguageChange('en')}
                      className={`flex items-center space-x-2 w-full px-3 py-2 text-xs hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200 ${
                        currentLanguage === 'en' 
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400' 
                          : 'text-gray-700 dark:text-gray-300'
                      }`}
                    >
                      <img 
                        src={EnglishFlag} 
                        alt="English" 
                        className="w-4 h-2 rounded-sm"
                      />
                      <span className="font-inter">EN</span>
                    </button>
                    <button
                      onClick={() => handleLanguageChange('fr')}
                      className={`flex items-center space-x-2 w-full px-3 py-2 text-xs hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200 ${
                        currentLanguage === 'fr' 
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400' 
                          : 'text-gray-700 dark:text-gray-300'
                      }`}
                    >
                      <img 
                        src={FrenchFlag} 
                        alt="French" 
                        className="w-4 h-2 rounded-sm"
                      />
                      <span className="font-inter">FR</span>
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Theme Toggle for Mobile */}
            <button
              onClick={handleThemeToggle}
              className={`relative inline-flex items-center w-12 h-6 rounded-full transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 ${
                isDarkMode ? 'bg-blue-600' : 'bg-gray-200'
              }`}
            >
              <div className={`absolute w-4 h-4 bg-white rounded-full shadow-sm transition-transform duration-300 ease-in-out flex items-center justify-center ${
                isDarkMode ? 'translate-x-7' : 'translate-x-1'
              }`}>
                {isDarkMode ? (
                  <svg className="w-2 h-2 text-blue-800" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                  </svg>
                ) : (
                  <svg className="w-2 h-2 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
                  </svg>
                )}
              </div>
            </button>

            {/* Mobile Hamburger Menu Button */}
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="bg-white dark:bg-dark-primary inline-flex items-center justify-center p-2 rounded-md text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-gray-50 dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-dark-primary"
              aria-controls="mobile-menu"
              aria-expanded={isMobileMenuOpen}
            >
              <span className="sr-only">Open main menu</span>
              {isMobileMenuOpen ? (
                <svg className="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </div>
      
      {/* Mobile menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden">
          <div className="px-2 pt-2 pb-3 space-y-1 bg-white dark:bg-dark-primary border-t border-gray-200 dark:border-gray-700 shadow-lg">
            {navItems.map((item) => (
              <button
                key={item.id}
                onClick={() => smoothScrollTo(item.id)}
                className={`block w-full text-left px-3 py-2 rounded-md text-base font-medium transition-all duration-200 ${
                  activeSection === item.id
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30'
                    : 'text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                {item.name}
              </button>
            ))}
          </div>
        </div>
      )}
    </nav>
  );
};

export default NavBar;
