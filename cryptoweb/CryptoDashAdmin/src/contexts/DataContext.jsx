import React, { createContext, useReducer, useCallback } from 'react';
import {
  getAllReservations,
  getTotalReservationsCount,
  getCompletedReservationsCount,
  getPendingReservationsCount,
  updateReservationStatus,
  deleteReservation,
  getAllDashboardDivs,
  updateDashboardDiv,
  getAllRegions,
  createRegion,
  addApartmentToRegion,
  updateApartment,
  deleteApartment,
  deleteRegion,
  handleApiError
} from '../utils/api';

// =============================================================================
//                            DATA CONTEXT SETUP
// =============================================================================

const DataContext = createContext();

// Data action types
const DATA_ACTIONS = {
  // Loading states
  SET_LOADING: 'SET_LOADING',
  SET_ERROR: 'SET_ERROR',
  CLEAR_ERROR: 'CLEAR_ERROR',
  
  // Reservations
  SET_RESERVATIONS: 'SET_RESERVATIONS',
  UPDATE_RESERVATION: 'UPDATE_RESERVATION',
  DELETE_RESERVATION: 'DELETE_RESERVATION',
  SET_RESERVATION_STATS: 'SET_RESERVATION_STATS',
  
  // Dashboard divs
  SET_DASHBOARD_DIVS: 'SET_DASHBOARD_DIVS',
  UPDATE_DASHBOARD_DIV: 'UPDATE_DASHBOARD_DIV',
  
  // Best sellers (regions/apartments)
  SET_REGIONS: 'SET_REGIONS',
  ADD_REGION: 'ADD_REGION',
  UPDATE_REGION: 'UPDATE_REGION',
  DELETE_REGION: 'DELETE_REGION',
  ADD_APARTMENT: 'ADD_APARTMENT',
  UPDATE_APARTMENT: 'UPDATE_APARTMENT',
  DELETE_APARTMENT: 'DELETE_APARTMENT'
};

// Initial state
const initialState = {
  // Loading and error states
  loading: {
    reservations: false,
    dashboardDivs: false,
    regions: false,
    stats: false
  },
  error: null,
  
  // Reservations data
  reservations: [],
  reservationStats: {
    total: 0,
    completed: 0,
    pending: 0
  },
  
  // Dashboard divs data
  dashboardDivs: [],
  
  // Best sellers data
  regions: []
};

// Data reducer
const dataReducer = (state, action) => {
  switch (action.type) {
    case DATA_ACTIONS.SET_LOADING:
      return {
        ...state,
        loading: {
          ...state.loading,
          [action.payload.type]: action.payload.isLoading
        }
      };
      
    case DATA_ACTIONS.SET_ERROR:
      return {
        ...state,
        error: action.payload.error
      };
      
    case DATA_ACTIONS.CLEAR_ERROR:
      return {
        ...state,
        error: null
      };
      
    case DATA_ACTIONS.SET_RESERVATIONS:
      return {
        ...state,
        reservations: action.payload.reservations
      };
      
    case DATA_ACTIONS.UPDATE_RESERVATION:
      return {
        ...state,
        reservations: state.reservations.map(reservation =>
          reservation.id === action.payload.id
            ? { ...reservation, ...action.payload.updates }
            : reservation
        )
      };
      
    case DATA_ACTIONS.DELETE_RESERVATION:
      return {
        ...state,
        reservations: state.reservations.filter(reservation => 
          reservation.id !== action.payload.id
        )
      };
      
    case DATA_ACTIONS.SET_RESERVATION_STATS:
      return {
        ...state,
        reservationStats: action.payload.stats
      };
      
    case DATA_ACTIONS.SET_DASHBOARD_DIVS:
      return {
        ...state,
        dashboardDivs: action.payload.divs
      };
      
    case DATA_ACTIONS.UPDATE_DASHBOARD_DIV:
      return {
        ...state,
        dashboardDivs: state.dashboardDivs.map(div =>
          div.id === action.payload.id
            ? { ...div, ...action.payload.updates }
            : div
        )
      };
      
    case DATA_ACTIONS.SET_REGIONS:
      return {
        ...state,
        regions: action.payload.regions
      };
      
    case DATA_ACTIONS.ADD_REGION:
      return {
        ...state,
        regions: [...state.regions, action.payload.region]
      };
      
    case DATA_ACTIONS.UPDATE_REGION:
      return {
        ...state,
        regions: state.regions.map(region =>
          region.id === action.payload.id
            ? { ...region, ...action.payload.updates }
            : region
        )
      };
      
    case DATA_ACTIONS.DELETE_REGION:
      return {
        ...state,
        regions: state.regions.filter(region => region.id !== action.payload.regionId)
      };
      
    case DATA_ACTIONS.ADD_APARTMENT:
      return {
        ...state,
        regions: state.regions.map(region =>
          region.id === action.payload.regionId
            ? {
                ...region,
                apartments: [...region.apartments, action.payload.apartment]
              }
            : region
        )
      };
      
    case DATA_ACTIONS.UPDATE_APARTMENT:
      return {
        ...state,
        regions: state.regions.map(region =>
          region.id === action.payload.regionId
            ? {
                ...region,
                apartments: region.apartments.map(apartment =>
                  apartment.id === action.payload.apartmentId
                    ? { ...apartment, ...action.payload.updates }
                    : apartment
                )
              }
            : region
        )
      };
      
    case DATA_ACTIONS.DELETE_APARTMENT:
      return {
        ...state,
        regions: state.regions.map(region =>
          region.id === action.payload.regionId
            ? {
                ...region,
                apartments: region.apartments.filter(apartment => 
                  apartment.id !== action.payload.apartmentId
                )
              }
            : region
        )
      };
      
    default:
      return state;
  }
};

// =============================================================================
//                            DATA PROVIDER COMPONENT
// =============================================================================

export const DataProvider = ({ children }) => {
  const [state, dispatch] = useReducer(dataReducer, initialState);

  // Generic error handler
  const handleError = useCallback((error) => {
    const errorInfo = handleApiError(error);
    dispatch({
      type: DATA_ACTIONS.SET_ERROR,
      payload: { error: errorInfo.message }
    });
  }, []);

  // Clear error
  const clearError = useCallback(() => {
    dispatch({ type: DATA_ACTIONS.CLEAR_ERROR });
  }, []);

  // =============================================================================
  //                            RESERVATIONS FUNCTIONS
  // =============================================================================

  const fetchReservations = useCallback(async () => {
    dispatch({
      type: DATA_ACTIONS.SET_LOADING,
      payload: { type: 'reservations', isLoading: true }
    });

    try {
      const result = await getAllReservations();
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.SET_RESERVATIONS,
          payload: { reservations: result.data }
        });
      } else {
        throw new Error(result.error?.message || 'Failed to fetch reservations');
      }
    } catch (error) {
      handleError(error);
    } finally {
      dispatch({
        type: DATA_ACTIONS.SET_LOADING,
        payload: { type: 'reservations', isLoading: false }
      });
    }
  }, [handleError]);

  const fetchReservationStats = useCallback(async () => {
    dispatch({
      type: DATA_ACTIONS.SET_LOADING,
      payload: { type: 'stats', isLoading: true }
    });

    try {
      const [totalResult, completedResult, pendingResult] = await Promise.all([
        getTotalReservationsCount(),
        getCompletedReservationsCount(),
        getPendingReservationsCount()
      ]);

      if (totalResult.success && completedResult.success && pendingResult.success) {
        dispatch({
          type: DATA_ACTIONS.SET_RESERVATION_STATS,
          payload: {
            stats: {
              total: totalResult.count,
              completed: completedResult.count,
              pending: pendingResult.count
            }
          }
        });
      } else {
        throw new Error('Failed to fetch reservation statistics');
      }
    } catch (error) {
      handleError(error);
    } finally {
      dispatch({
        type: DATA_ACTIONS.SET_LOADING,
        payload: { type: 'stats', isLoading: false }
      });
    }
  }, [handleError]);

  const updateReservation = useCallback(async (reservationId, status) => {
    try {
      const result = await updateReservationStatus(reservationId, status);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.UPDATE_RESERVATION,
          payload: {
            id: reservationId,
            updates: { status }
          }
        });
        // Refresh stats after status update
        fetchReservationStats();
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to update reservation');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError, fetchReservationStats]);
  
  const deleteReservationData = useCallback(async (reservationId) => {
    try {
      const result = await deleteReservation(reservationId);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.DELETE_RESERVATION,
          payload: {
            id: reservationId
          }
        });
        // Refresh stats after deletion
        fetchReservationStats();
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to delete reservation');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError, fetchReservationStats]);

  // =============================================================================
  //                            DASHBOARD DIVS FUNCTIONS
  // =============================================================================

  const fetchDashboardDivs = useCallback(async () => {
    dispatch({
      type: DATA_ACTIONS.SET_LOADING,
      payload: { type: 'dashboardDivs', isLoading: true }
    });

    try {
      const result = await getAllDashboardDivs();
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.SET_DASHBOARD_DIVS,
          payload: { divs: result.data }
        });
      } else {
        throw new Error(result.error?.message || 'Failed to fetch dashboard divs');
      }
    } catch (error) {
      handleError(error);
    } finally {
      dispatch({
        type: DATA_ACTIONS.SET_LOADING,
        payload: { type: 'dashboardDivs', isLoading: false }
      });
    }
  }, [handleError]);

  const updateDashboardDivData = useCallback(async (divId, divData) => {
    try {
      const result = await updateDashboardDiv(divId, divData);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.UPDATE_DASHBOARD_DIV,
          payload: {
            id: divId,
            updates: result.data
          }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to update dashboard div');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  // =============================================================================
  //                            REGIONS/APARTMENTS FUNCTIONS
  // =============================================================================

  const fetchRegions = useCallback(async () => {
    dispatch({
      type: DATA_ACTIONS.SET_LOADING,
      payload: { type: 'regions', isLoading: true }
    });

    try {
      const result = await getAllRegions();
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.SET_REGIONS,
          payload: { regions: result.data }
        });
      } else {
        throw new Error(result.error?.message || 'Failed to fetch regions');
      }
    } catch (error) {
      handleError(error);
    } finally {
      dispatch({
        type: DATA_ACTIONS.SET_LOADING,
        payload: { type: 'regions', isLoading: false }
      });
    }
  }, [handleError]);

  const addRegion = useCallback(async (regionName) => {
    try {
      console.log('🔄 DataContext: Creating region:', regionName);
      const result = await createRegion(regionName);
      console.log('📤 DataContext: Region API result:', result);
      
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.ADD_REGION,
          payload: { region: result.data }
        });
        console.log('✅ DataContext: Region added to state');
        return result; // Return the full result with data
      } else {
        console.error('❌ DataContext: Region creation failed:', result);
        throw new Error(result.error?.message || 'Failed to create region');
      }
    } catch (error) {
      console.error('❌ DataContext: Region creation error:', error);
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const addApartment = useCallback(async (regionId, apartmentData) => {
    try {
      const result = await addApartmentToRegion(regionId, apartmentData);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.ADD_APARTMENT,
          payload: {
            regionId,
            apartment: result.data
          }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to add apartment');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const updateApartmentData = useCallback(async (regionId, apartmentId, apartmentData) => {
    try {
      const result = await updateApartment(regionId, apartmentId, apartmentData);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.UPDATE_APARTMENT,
          payload: {
            regionId,
            apartmentId,
            updates: result.data
          }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to update apartment');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const deleteApartmentData = useCallback(async (regionId, apartmentId) => {
    try {
      const result = await deleteApartment(regionId, apartmentId);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.DELETE_APARTMENT,
          payload: {
            regionId,
            apartmentId
          }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to delete apartment');
      }
    } catch (error) {
      handleError(error);
      return { success: false, error: error.message };
    }
  }, [handleError]);

  const deleteRegionData = useCallback(async (regionId) => {
    try {
      const result = await deleteRegion(regionId);
      if (result.success) {
        dispatch({
          type: DATA_ACTIONS.DELETE_REGION,
          payload: {
            regionId
          }
        });
        return { success: true };
      } else {
        throw new Error(result.error?.message || 'Failed to delete region');
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
    
    // Reservations
    fetchReservations,
    fetchReservationStats,
    updateReservation,
    deleteReservationData,
    
    // Dashboard divs
    fetchDashboardDivs,
    updateDashboardDivData,
    
    // Regions/apartments
    fetchRegions,
    addRegion,
    addApartment,
    updateApartmentData,
    deleteApartmentData,
    deleteRegionData
  };

  return (
    <DataContext.Provider value={value}>
      {children}
    </DataContext.Provider>
  );
};

export default DataContext;
