import { useContext } from 'react';
import DataContext from '../contexts/DataContext';

// =============================================================================
//                            CUSTOM HOOK
// =============================================================================

export const useData = () => {
  const context = useContext(DataContext);
  
  if (!context) {
    throw new Error('useData must be used within a DataProvider');
  }
  
  return context;
};

export default useData;
