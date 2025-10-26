import React, { createContext, useContext, useReducer, useCallback } from 'react';
import {
  createApartmentType,
  getAllApartmentTypes,
  getApartmentType,
  updateApartmentTypeById,
  deleteApartmentTypeById,
  handleApiError
} from '../utils/api';

// =============================================================================
//                            APARTMENT TYPE CONTEXT SETUP
// =============================================================================

const ApartmentTypeContext = createContext();

// Apartment type action types
const APARTMENT_TYPE_ACTIONS = {
  // Loading states
  SET_LOADING: 'SET_LOADING',
  SET_ERROR: 'SET_ERROR',
  CLEAR_ERROR: 'CLEAR_ERROR',
  
  // Apartment types
  SET_APARTMENT_TYPES: 'SET_APARTMENT_TYPES',
  ADD_APARTMENT_TYPE: 'ADD_APARTMENT_TYPE',
  UPDATE_APARTMENT_TYPE: 'UPDATE_APARTMENT_TYPE',
  DELETE_APARTMENT_TYPE: 'DELETE_APARTMENT_TYPE'
};

// Initial state
const initialState = {
  // Loading and error states
  loading: {
    apartmentTypes: false
  },
  error: null,
  
  // Apartment types data
  apartmentTypes: []
};

// Apartment type reducer
const apartmentTypeReducer = (state, action) => {
  switch (action.type) {
    case APARTMENT_TYPE_ACTIONS.SET_LOADING:
      return {
        ...state,
        loading: {
          ...state.loading,
          [action.payload.type]: action.payload.isLoading
        }
      };
      
    case APARTMENT_TYPE_ACTIONS.SET_ERROR:
      return {
        ...state,
        error: action.payload.error
      };
      
    case APARTMENT_TYPE_ACTIONS.CLEAR_ERROR:
      return {
        ...state,
        error: null
      };
      
    case APARTMENT_TYPE_ACTIONS.SET_APARTMENT_TYPES:
      return {
        ...state,
        apartmentTypes: action.payload.apartmentTypes
      };
      
    case APARTMENT_TYPE_ACTIONS.ADD_APARTMENT_TYPE:
      return {
        ...state,
        apartmentTypes: [...state.apartmentTypes, action.payload.apartmentType]
      };
      
    case APARTMENT_TYPE_ACTIONS.UPDATE_APARTMENT_TYPE:
      return {
        ...state,
        apartmentTypes: state.apartmentTypes.map(type =>
          type.id === action.payload.id
            ? { ...type, ...action.payload.updates }
            : type
        )
      };
      
    case APARTMENT_TYPE_ACTIONS.DELETE_APARTMENT_TYPE:
      return {
        ...state,
        apartmentTypes: state.apartmentTypes.filter(type =>
          type.id !== action.payload.id
        )
      };
      
    default:
      return state;
  }
};

// =============================================================================
//                            APARTMENT TYPE PROVIDER COMPONENT
// =============================================================================

export const ApartmentTypeProvider = ({ children }) => {
  const [state, dispatch] = useReducer(apartmentTypeReducer, initialState);

  // Generic error handler
  const handleError = useCallback((error) => {
    const errorInfo = handleApiError(error);
    dispatch({
      type: APARTMENT_TYPE_ACTIONS.SET_ERROR,
      payload: { error: errorInfo.message }
    });
  }, []);

  // Clear error
  const clearError = useCallback(() => {
    dispatch({ type: APARTMENT_TYPE_ACTIONS.CLEAR_ERROR });
  }, []);

  // =============================================================================
  //                            APARTMENT TYPE FUNCTIONS
  // =============================================================================

  const fetchApartmentTypes = useCallback(async () => {
    dispatch({
      type: APARTMENT_TYPE_ACTIONS.SET_LOADING,
      payload: { type: 'apartmentTypes', isLoading: true }
    });

    try {
      const result = await getAllApartmentTypes();
      if (result.success) {
        dispatch({
          type: APARTMENT_TYPE_ACTIONS.SET_APARTMENT_TYPES,
          payload: { apartmentTypes: result.data }
        });
      } else {
        throw new Error(result.error?.message || 'Failed to fetch apartment types');
      }
    } catch (error) {
      handleError(error);
    } finally {
      dispatch({
        type: APARTMENT_TYPE_ACTIONS.SET_LOADING,
        payload: { type: 'apartmentTypes', isLoading: false }
      });
    }
  }, [handleError]);

  const addApartmentType = useCallback(async (name) => {
    try {
      const result = await createApartmentType(name);
      if (result.success) {
        dispatch({
          type: APARTMENT_TYPE_ACTIONS.ADD_APARTMENT_TYPE,
          payload: { apartmentType: result.data }
        });
        return { success: true, data: result.data };
      } else {
        throw new Error(result.error?.message || 'Failed to create apartment type');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const updateApartmentType = useCallback(async (typeId, name) => {
    try {
      const result = await updateApartmentTypeById(typeId, name);
      if (result.success) {
        dispatch({
          type: APARTMENT_TYPE_ACTIONS.UPDATE_APARTMENT_TYPE,
          payload: {
            id: typeId,
            updates: result.data
          }
        });
        return { success: true, data: result.data };
      } else {
        throw new Error(result.error?.message || 'Failed to update apartment type');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const deleteApartmentType = useCallback(async (typeId) => {
    try {
      const result = await deleteApartmentTypeById(typeId);
      if (result.success) {
        dispatch({
          type: APARTMENT_TYPE_ACTIONS.DELETE_APARTMENT_TYPE,
          payload: { id: typeId }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to delete apartment type');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const getApartmentTypeById = useCallback(async (typeId) => {
    try {
      const result = await getApartmentType(typeId);
      if (result.success) {
        return { success: true, data: result.data };
      } else {
        throw new Error(result.error?.message || 'Failed to get apartment type');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  // Context value
  const value = {
    ...state,
    
    // Error handling
    clearError,
    
    // Apartment types
    fetchApartmentTypes,
    addApartmentType,
    updateApartmentType,
    deleteApartmentType,
    getApartmentTypeById
  };

  return (
    <ApartmentTypeContext.Provider value={value}>
      {children}
    </ApartmentTypeContext.Provider>
  );
};

// =============================================================================
//                            CUSTOM HOOK
// =============================================================================

export const useApartmentTypes = () => {
  const context = useContext(ApartmentTypeContext);
  
  if (!context) {
    throw new Error('useApartmentTypes must be used within an ApartmentTypeProvider');
  }
  
  return context;
};

export default ApartmentTypeContext;
