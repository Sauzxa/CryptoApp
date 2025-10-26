import { useContext } from 'react';
import HeroContext from '../context/HeroContext';

export const useHero = () => {
  const context = useContext(HeroContext);
  if (!context) {
    throw new Error('useHero must be used within a HeroProvider');
  }
  return context;
};
