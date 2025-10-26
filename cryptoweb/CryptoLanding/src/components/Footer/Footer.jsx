import React from 'react';
import FooterLogo from '../../assets/images/logos/FooterLogo.png';
import FacebookLogo from '../../assets/images/logos/facebookLogo.png';
import InstagramLogo from '../../assets/images/logos/instagram-logo.png';
import { useLanguage } from '../../contexts/LanguageContext';

const Footer = () => {
  const { t } = useLanguage();
  
  // Google Maps location for La Promotion Immobilière Crypto
  const GoogleMapsEmbed = () => {
    return (
      <div className="w-full h-64 rounded-lg overflow-hidden shadow-lg">
        <iframe
          src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3196.3!2d3.1922852!3d36.7427417!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x128e4fe4aea58f3b%3A0x31348273cd3ae100!2sla%20promotion%20immobili%C3%A8re%20crypto!5e0!3m2!1sen!2sus!4v1625654321123!5m2!1sen!2sus"
          width="100%"
          height="100%"
          style={{ border: 0 }}
          allowFullScreen=""
          loading="lazy"
          referrerPolicy="no-referrer-when-downgrade"
          title={t('footer.mapTitle')}
        />
      </div>
    );
  };

  return (
    <footer style={{ backgroundColor: '#1D3557' }} className="text-white py-16 px-4 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16">
          
          {/* Left Section - Logo, Company Info and Social Media */}
          <div className="flex flex-col">
            <div className="flex items-center mb-6">
              <img 
                src={FooterLogo} 
                alt="Crypto Immobilier Logo" 
                className="w-16 h-auto mr-4 object-contain"
              />
              <h3 className="text-xl font-bold font-inter">
                {t('footer.companyName').split('\n').map((line, index) => (
                  <React.Fragment key={index}>
                    {line}
                    {index < t('footer.companyName').split('\n').length - 1 && <br />}
                  </React.Fragment>
                ))}
              </h3>
            </div>
            
            <p className="text-gray-300 text-sm leading-relaxed mb-8">
              {t('footer.description')}
            </p>

            {/* Social Media Links */}
            <div className="mb-8">
              <h4 className="text-lg font-semibold mb-4">{t('footer.socialTitle')}</h4>
              <div className="flex space-x-6">
                <a 
                target='_blank'
                  href="https://www.facebook.com/profile.php?id=61557069279440&mibextid=ZbWKwL" 
                  className="hover:opacity-80 transition-opacity duration-200"
                  alt={t('footer.facebookAlt')}
                >
                  <img src={FacebookLogo} alt="Facebook" className="w-6 h-6 object-contain" />
                </a>
                <a 
                  target='_blank'
                  href="#" 
                  className="hover:opacity-80 transition-opacity duration-200"
                  alt={t('footer.instagramAlt')}
                >
                  <img src={InstagramLogo} alt="Instagram" className="w-6 h-6 object-contain" />
                </a>
              </div>
            </div>
          </div>

          {/* Right Section - Google Maps Embed */}
          <div className="flex flex-col">
            <h4 className="text-lg font-semibold mb-6">{t('footer.locationTitle')}</h4>
            <GoogleMapsEmbed />
          </div>
        </div>

        {/* Bottom Section - Copyright */}
        <div className="border-t border-gray-600 mt-12 pt-8">
          <div className="text-center">
            <p className="text-gray-400 text-sm">
              {t('footer.copyright')}
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
