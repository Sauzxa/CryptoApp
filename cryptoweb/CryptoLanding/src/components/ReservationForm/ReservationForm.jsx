import React, { useState, useEffect } from 'react';
import Logo from '../../assets/images/logos/Logo.png';
import { useLanguage } from '../../contexts/LanguageContext';

const ReservationForm = () => {
  const { t } = useLanguage();
  const [formData, setFormData] = useState({
    name: '',
    number: '',
    reservationDate: '',
    typeAppartement: '',
    message: ''
  });

  const [apartmentTypes, setApartmentTypes] = useState([]);
  const [loadingTypes, setLoadingTypes] = useState(true);
  const [submitLoading, setSubmitLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [dropdownRef, setDropdownRef] = useState(null);

  // Fetch apartment types from database on component mount
  useEffect(() => {
    fetchApartmentTypes();
  }, []);
  const apiUrl = import.meta.env.VITE_API_URL_LANDING || '/api';
  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef && !dropdownRef.contains(event.target)) {
        setIsDropdownOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [dropdownRef]);

  const fetchApartmentTypes = async () => {
    try {
      setLoadingTypes(true);
      
      const response = await fetch(`${apiUrl}/apartment-types`);
      const data = await response.json();
      
      if (data.success && data.data) {
        // Extract just the names from the apartment type objects
        const typeNames = data.data.map(type => type.name);
        setApartmentTypes(typeNames);
      } else {
        // Silently fallback to static types if API fails
        setApartmentTypes(['Studio', 'F1', 'F2', 'F3', 'F4', 'F5', 'Duplex', 'Villa']);
      }
    } catch (err) {
      console.error('Error fetching apartment types:', err);
      // Silently fallback to static types if API fails
      setApartmentTypes(['Studio', 'F1', 'F2', 'F3', 'F4', 'F5', 'Duplex', 'Villa']);
    } finally {
      setLoadingTypes(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear error message when user starts typing
    if (error) setError('');
    if (success) setSuccess('');
  };

  const handleApartmentTypeSelect = (type) => {
    setFormData(prev => ({
      ...prev,
      typeAppartement: type
    }));
    setIsDropdownOpen(false);
    // Clear error message when user selects
    if (error) setError('');
    if (success) setSuccess('');
  };

  const toggleDropdown = () => {
    if (!loadingTypes) {
      setIsDropdownOpen(!isDropdownOpen);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitLoading(true);
    setError('');
    setSuccess('');

    try {
      // Use environment variable or fallback to relative URL for Docker production
      const response = await fetch(`${apiUrl}/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (data.success) {
        setSuccess(t('reservation.form.successMessage'));
        // Reset form
        setFormData({
          name: '',
          number: '',
          reservationDate: '',
          typeAppartement: '',
          message: ''
        });
      } else {
        setError(t('reservation.form.errorMessage'));
      }
    } catch (err) {
      setError(t('reservation.form.networkError'));
      console.error('Error submitting reservation:', err);
    } finally {
      setSubmitLoading(false);
    }
  };

  return (
    <section className="bg-gradient-to-b from-light-gradient-start to-light-gradient-end dark:from-dark-gradient-start dark:to-dark-gradient-end py-8 sm:py-12 lg:py-16 px-4 lg:px-8 transition-all duration-300 ease-in-out">
      <div className="max-w-7xl mx-auto">
        <div className="flex flex-col lg:flex-row gap-8 sm:gap-10 lg:gap-16">
          {/* Left Section - Logo and Info */}
          <div className="flex-1 lg:pr-8">
            <div className="flex items-center mb-6 sm:mb-8 lg:mb-12">
              <img 
                src={Logo} 
                alt="Crypto Immobilier Logo" 
                className="w-12 h-12 sm:w-14 sm:h-14 lg:w-16 lg:h-16 mr-3 sm:mr-4"
              />
              <h2 className="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-gray-800 dark:text-white font-inter leading-tight">
                {t('reservation.title')}
              </h2>
            </div>
            
            <p className="text-gray-600 dark:text-gray-300 text-sm sm:text-base lg:text-lg leading-relaxed">
              {t('reservation.description')}
            </p>
            
            <div className="space-y-6 sm:space-y-8 mt-6 sm:mt-8 lg:mt-10">
                <div className="flex items-center">
                  <div className="w-5 h-5 sm:w-6 sm:h-6 mr-3 sm:mr-4 flex-shrink-0">
                    <svg className="w-full h-full text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"/>
                      <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"/>
                    </svg>
                  </div>
                  <span className="text-gray-700 dark:text-gray-300 text-sm sm:text-base break-all">{t('reservation.contact.email')}</span>
                </div>
                
                <div className="flex items-start">
                  <div className="w-5 h-5 sm:w-6 sm:h-6 mr-3 sm:mr-4 flex-shrink-0 mt-1">
                    <svg className="w-full h-full text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd"/>
                    </svg>
                  </div>
                  <div>
                    <p className="text-gray-700 dark:text-gray-300 text-sm sm:text-base">{t('reservation.contact.address1')}</p>
                    <p className="text-gray-700 dark:text-gray-300 text-sm sm:text-base">{t('reservation.contact.address2')}</p>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <div className="w-5 h-5 sm:w-6 sm:h-6 mr-3 sm:mr-4 flex-shrink-0">
                    <svg className="w-full h-full text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"/>
                    </svg>
                  </div>
                  <span className="text-gray-700 dark:text-gray-300 text-sm sm:text-base">{t('reservation.contact.phone')}</span>
                </div>
            </div>
          </div>

          {/* Right Section - Form */}
          <div className="flex-1">
            {/* Error and Success Messages */}
            {error && (
              <div className="mb-4 p-3 bg-red-100 dark:bg-red-900/20 border border-red-400 dark:border-red-800 text-red-700 dark:text-red-400 rounded-lg">
                {error}
              </div>
            )}
            
            {success && (
              <div className="mb-4 p-3 bg-green-100 dark:bg-green-900/20 border border-green-400 dark:border-green-800 text-green-700 dark:text-green-400 rounded-lg">
                {success}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4 sm:space-y-6">
              {/* Name Field */}
              <div>
                <input
                  type="text"
                  name="name"
                  placeholder={t('reservation.form.namePlaceholder')}
                  value={formData.name}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 sm:px-4 sm:py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 bg-white dark:bg-gray-800 dark:text-white text-sm sm:text-base"
                />
              </div>
              
              {/* Phone Number Field */}
              <div>
                <input
                  type="tel"
                  name="number"
                  placeholder={t('reservation.form.phonePlaceholder')}
                  value={formData.number}
                  onChange={handleInputChange}
                  required
                  maxLength={10}
                  className="w-full px-3 py-2 sm:px-4 sm:py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 bg-white dark:bg-gray-800 dark:text-white text-sm sm:text-base"
                />
              </div>
              
              {/* Reservation Date Field */}
              <div>
                <input
                  type="date"
                  name="reservationDate"
                  value={formData.reservationDate}
                  onChange={handleInputChange}
                  required
                  min={new Date().toISOString().split('T')[0]} // Prevent past dates
                  className="w-full px-3 py-2 sm:px-4 sm:py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 bg-white dark:bg-gray-800 dark:text-white text-sm sm:text-base"
                />
              </div>
              
              {/* Custom Apartment Type Dropdown */}
              <div className="relative" ref={setDropdownRef}>
                {/* Hidden input for form validation */}
                <input
                  type="hidden"
                  name="typeAppartement"
                  value={formData.typeAppartement}
                  required
                />
                {/* Dropdown Button */}
                <div
                  onClick={toggleDropdown}
                  className={`w-full px-3 py-2 sm:px-4 sm:py-3 pr-10 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 bg-white dark:bg-gray-800 text-sm sm:text-base cursor-pointer hover:border-gray-400 dark:hover:border-gray-500 ${
                    loadingTypes ? 'cursor-not-allowed opacity-70' : ''
                  } ${
                    !formData.typeAppartement ? 'text-gray-400 dark:text-gray-500' : 'text-gray-900 dark:text-gray-100'
                  } ${
                    isDropdownOpen ? 'ring-2 ring-blue-500 border-transparent' : ''
                  }`}
                >
                  <span className="block truncate">
                    {loadingTypes 
                      ? t('reservation.form.loadingTypes') 
                      : formData.typeAppartement || t('reservation.form.apartmentTypePlaceholder')
                    }
                  </span>
                </div>
                
                {/* Dropdown Arrow */}
                <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                  {loadingTypes ? (
                    <div className="animate-spin h-4 w-4 border-2 border-gray-300 border-t-blue-500 rounded-full"></div>
                  ) : (
                    <svg
                      className={`h-5 w-5 transition-all duration-200 text-gray-400 dark:text-gray-500 ${
                        isDropdownOpen ? 'rotate-180' : 'rotate-0'
                      }`}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M19 9l-7 7-7-7"
                      />
                    </svg>
                  )}
                </div>

                {/* Dropdown Menu */}
                {isDropdownOpen && !loadingTypes && apartmentTypes.length > 0 && (
                  <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg max-h-60 overflow-auto">
                    {apartmentTypes.map((type, index) => (
                      <div
                        key={index}
                        onClick={() => handleApartmentTypeSelect(type)}
                        className={`px-3 py-2 sm:px-4 sm:py-3 cursor-pointer text-sm sm:text-base transition-all duration-150 hover:bg-blue-50 dark:hover:bg-blue-900/30 hover:text-blue-700 dark:hover:text-blue-400 ${
                          formData.typeAppartement === type 
                            ? 'bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-400 font-medium' 
                            : 'text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700'
                        } ${
                          index === 0 ? 'rounded-t-lg' : ''
                        } ${
                          index === apartmentTypes.length - 1 ? 'rounded-b-lg' : 'border-b border-gray-100 dark:border-gray-700'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="block truncate">{type}</span>
                          {formData.typeAppartement === type && (
                            <svg
                              className="h-4 w-4 text-blue-600 dark:text-blue-400"
                              fill="currentColor"
                              viewBox="0 0 20 20"
                            >
                              <path
                                fillRule="evenodd"
                                d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                clipRule="evenodd"
                              />
                            </svg>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Empty State */}
                {isDropdownOpen && !loadingTypes && apartmentTypes.length === 0 && (
                  <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg shadow-lg">
                    <div className="px-3 py-2 sm:px-4 sm:py-3 text-sm sm:text-base text-gray-500 dark:text-gray-400 text-center">
                      {t('reservation.form.noTypes')}
                    </div>
                  </div>
                )}
              </div>
              
              {/* Message Field (Optional) */}
              <div>
                <textarea
                  name="message"
                  placeholder={t('reservation.form.messagePlaceholder')}
                  value={formData.message}
                  onChange={handleInputChange}
                  rows={4}
                  className="w-full px-3 py-2 sm:px-4 sm:py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 bg-white dark:bg-gray-800 dark:text-white resize-none text-sm sm:text-base"
                />
              </div>
              
              {/* Submit Button */}
              <button
                type="submit"
                disabled={submitLoading}
                className={`w-full sm:w-32 font-semibold py-2 px-4 sm:py-3 sm:px-6 rounded-lg transition-colors duration-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-800 outline-none text-sm sm:text-base ${
                  submitLoading
                    ? 'bg-gray-400 dark:bg-gray-600 cursor-not-allowed'
                    : 'bg-primary-button hover:bg-red-700 text-white'
                }`}
              >
                {submitLoading ? t('reservation.form.submitting') : t('reservation.form.submitButton')}
              </button>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ReservationForm;
