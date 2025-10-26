import { useContext } from 'react';
import DescriptionContext from '../context/DescriptionContext';

export const useDescription = () => {
  const context = useContext(DescriptionContext);
  if (!context) {
    throw new Error('useDescription must be used within a DescriptionProvider');
  }
  return context;
};
