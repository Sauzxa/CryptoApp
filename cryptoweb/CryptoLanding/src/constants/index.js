import HeroImage from '../assets/images/HeroImage.png';
import Apartment1 from '../assets/images/apartments/appartement1.png';
import Apartment2 from '../assets/images/apartments/appartement2.png';
import Apartment3 from '../assets/images/apartments/appartement3.png';

// Region images - Hydra
import HydraApt1 from '../assets/images/regions/hydra/Appartement-3chambres-séjour.png';
import HydraApt2 from '../assets/images/regions/hydra/Appartement-Charmant.png';
import HydraApt3 from '../assets/images/regions/hydra/Majestueux-Appartement-2pièces.png';
import HydraApt4 from '../assets/images/regions/hydra/Somptueux-appartement.png';

// Region images - Bab Ezzouar
import BbzApt1 from '../assets/images/regions/bbz/Appartement-Bordj-El-Kiffan-bbz.png';
import BbzApt2 from '../assets/images/regions/bbz/Appartement-Draria-bbz.png';
import BbzApt3 from '../assets/images/regions/bbz/Au-refuge-de-Nadia-bbz.png';

// Region images - Cheraga
import CheragaApt1 from '../assets/images/regions/cheraga/Apartment-bénimessous1-cheraga.png';
import CheragaApt2 from '../assets/images/regions/cheraga/appartementF4-chraga.png';
import CheragaApt3 from '../assets/images/regions/cheraga/sweetHome-Chraga.png';

// Default Hero Section Content
export const DEFAULT_HERO_CONTENT = {
  title: "CHOSE. YOUR. OWN. HOME.",
  statistics: [
    {
      number: "5,200+",
      label: "Properties Listed"
    },
    {
      number: "1,800+",
      label: "Happy Clients Served"
    },
    {
      number: "Average 14",
      label: "Days to Close a Deal"
    }
  ],
  backgroundImage: HeroImage
};

// Default Description Section Content
export const DEFAULT_DESCRIPTION_CONTENT = {
  title: "Find Your Perfect Home in Algeria",
  description: "Explore verified listings across Algiers, Oran, Constantine, and beyond. From city apartments to coastal villas, we connect you directly with trusted agents and property owners — no middleman, no hidden fees.",
  apartments: [
    {
      id: 1,
      price: "DZD 34,100",
      period: "F3 | Per Month",
      image: Apartment1,
      zIndex: 30
    },
    {
      id: 2,
      price: "DZD 45,800",
      period: "F4 | Per Month", 
      image: Apartment2,
      zIndex: 20
    },
    {
      id: 3,
      price: "DZD 28,500",
      period: "F2 | Per Month",
      image: Apartment3,
      zIndex: 10
    }
  ]
};

// Default Sellers Section Content
export const DEFAULT_SELLERS_CONTENT = {
  // Available regions with their apartments
  regions: [
    {
      id: "hydra",
      name: "Hydra",
      apartments: [
        {
          id: 1,
          name: "Appartement 3chambres séjour",
          image: HydraApt1,
          availability: "Available"
        },
        {
          id: 2,
          name: "Appartement Charmant",
          image: HydraApt2,
          availability: "Available"
        },
        {
          id: 3,
          name: "Majestueux Appartement 2pièces",
          image: HydraApt3,
          availability: "Unavailable"
        },
        {
          id: 4,
          name: "Somptueux appartement",
          image: HydraApt4,
          availability: "Available"
        }
      ]
    },
    {
      id: "bab-ezzouar",
      name: "Bab Ezzouar",
      apartments: [
        {
          id: 5,
          name: "Appartement Bordj El Kiffan",
          image: BbzApt1,
          availability: "Available"
        },
        {
          id: 6,
          name: "Appartement Draria",
          image: BbzApt2,
          availability: "Available"
        },
        {
          id: 7,
          name: "Au refuge de Nadia",
          image: BbzApt3,
          availability: "Unavailable"
        }
      ]
    },
    {
      id: "cheraga",
      name: "Cheraga",
      apartments: [
        {
          id: 8,
          name: "Apartment bénimessous",
          image: CheragaApt1,
          availability: "Available"
        },
        {
          id: 9,
          name: "Appartement F4 Chraga",
          image: CheragaApt2,
          availability: "Available"
        },
        {
          id: 10,
          name: "Sweet Home Chraga",
          image: CheragaApt3,
          availability: "Available"
        }
      ]
    }
  ]
};

// API Endpoints - utilise les URLs relatives en production
const isDevelopment = import.meta.env.NODE_ENV === 'development';
const BASE_URL = isDevelopment ? (import.meta.env.VITE_API_URL || 'http://localhost:8000') : '';

export const API_ENDPOINTS = {
  HERO_CONTENT: `${BASE_URL}/api/hero-content`,
  DESCRIPTION_CONTENT: `${BASE_URL}/api/description-content`,
  SELLERS_CONTENT: `${BASE_URL}/api/sellers-content`,
  HERO_SECTION_NUMBERS: `${BASE_URL}/api/hero-section-numbers`,
  DASHBOARD_DIVS: `${BASE_URL}/api/dashboard/divs`,
  BESTSELLERS_REGIONS: `${BASE_URL}/api/bestsellers/regions`,
  // Add more endpoints here as needed
};