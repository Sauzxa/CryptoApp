
import NavBar from './components/Header/NavBar';
import Hero from './components/Hero';
import Description from './components/Description';
import SellersSection from './components/SellersSection';
import ReservationForm from './components/ReservationForm';
import Footer from './components/Footer';
import { HeroProvider } from './context/HeroContext';
import { DescriptionProvider } from './context/DescriptionContext';
import { LanguageProvider } from './contexts/LanguageContext';
import { ThemeProvider } from './contexts/ThemeContext';
// eslint-disable-next-line no-unused-vars
import { motion } from 'framer-motion';

// Animation variants for sections
const sectionVariants = {
  hidden: { 
    opacity: 0, 
    y: 50,
    transition: { duration: 0.6 }
  },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: { duration: 0.8, ease: "easeOut" }
  }
};

// Animation variants specifically for footer to avoid conflicts
const footerVariants = {
  hidden: { 
    opacity: 0, 
    y: 30,
    transition: { duration: 0.4 }
  },
  visible: { 
    opacity: 1, 
    y: 0,
    transition: { duration: 0.6, ease: "easeOut" }
  }
};

function App() {
  return (
    <ThemeProvider>
      <LanguageProvider>
        <HeroProvider>
          <DescriptionProvider>
            <div className="relative transition-colors duration-300 ease-in-out bg-light-primary dark:bg-dark-primary text-black dark:text-white">
              <NavBar />
            
            {/* Hero Section */}
            <motion.section
              id="home"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true, amount: 0.3 }}
              variants={sectionVariants}
            >
              <Hero />
            </motion.section>

            {/* About Section - Description */}
            <motion.section
              id="about"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: false, amount: 0.3 }}
              variants={sectionVariants}
            >
              <Description />
            </motion.section>

            {/* Sellers Section */}
            <motion.section
              id="sellers"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: false, amount: 0.3 }}
              variants={sectionVariants}
            >
              <SellersSection />
            </motion.section>

            {/* Reservation Section */}
            <motion.section
              id="reservation"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: false, amount: 0.1, margin: "-50px" }}
              variants={sectionVariants}
            >
              <ReservationForm />
            </motion.section>

            {/* Footer Section */}
            <motion.section
              id="footer"
              initial="hidden"
              whileInView="visible"
              viewport={{ once: false, amount: 0.25, margin: "-100px" }}
              variants={footerVariants}
            >
              <Footer />
            </motion.section>
          </div>
        </DescriptionProvider>
      </HeroProvider>
    </LanguageProvider>
  </ThemeProvider>
  )
}

export default App
