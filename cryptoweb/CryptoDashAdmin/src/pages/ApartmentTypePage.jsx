import React, { useState, useEffect } from 'react';
import { useApartmentTypes } from '../contexts/ApartmentTypeContext';
import DashboardWelcome from '../DashboardWelcome';

const ApartmentTypePage = () => {
  const { 
    apartmentTypes, 
    loading, 
    error, 
    fetchApartmentTypes, 
    addApartmentType, 
    updateApartmentType, 
    deleteApartmentType,
    clearError 
  } = useApartmentTypes();
  
  const [newTypeName, setNewTypeName] = useState('');
  const [editingType, setEditingType] = useState(null);
  const [editTypeName, setEditTypeName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Load apartment types on component mount
  useEffect(() => {
    fetchApartmentTypes();
  }, [fetchApartmentTypes]);

  const handleAddType = async () => {
    if (!newTypeName.trim()) {
      alert('Please enter an apartment type name');
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await addApartmentType(newTypeName.trim());
      if (result.success) {
        setNewTypeName('');
        fetchApartmentTypes(); // Refresh the list
      } else {
        alert('Failed to add apartment type: ' + (result.error || 'Unknown error'));
      }
    } catch (error) {
      alert('Error adding apartment type: ' + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditType = (apartmentType) => {
    setEditingType(apartmentType);
    setEditTypeName(apartmentType.name);
  };

  const handleUpdateType = async () => {
    if (!editTypeName.trim()) {
      alert('Please enter an apartment type name');
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await updateApartmentType(editingType.id, editTypeName.trim());
      if (result.success) {
        setEditingType(null);
        setEditTypeName('');
        fetchApartmentTypes(); // Refresh the list
      } else {
        alert('Failed to update apartment type: ' + (result.error || 'Unknown error'));
      }
    } catch (error) {
      alert('Error updating apartment type: ' + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteType = async (apartmentType) => {
    if (!window.confirm(`Are you sure you want to delete "${apartmentType.name}"?`)) {
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await deleteApartmentType(apartmentType.id);
      if (result.success) {
        fetchApartmentTypes(); // Refresh the list
      } else {
        alert('Failed to delete apartment type: ' + (result.error || 'Unknown error'));
      }
    } catch (error) {
      alert('Error deleting apartment type: ' + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancelEdit = () => {
    setEditingType(null);
    setEditTypeName('');
  };

  return (
    <div style={{
      padding: '40px',
      textAlign: 'center',
      color: 'white'
    }}>
      <DashboardWelcome username="CRYPTO USER" />
      
      {/* Page Header */}
      <div style={{
        marginBottom: '40px',
        marginTop: '20px'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          marginBottom: '10px',
          fontWeight: 'bold',
          color: 'white'
        }}>
          Apartment Types Management
        </h1>
        <p style={{
          fontSize: '1.2rem',
          opacity: 0.9,
          color: 'white',
          margin: 0
        }}>
          Add, edit, and manage apartment types for your properties
        </p>
      </div>

      {/* Main content section */}
      <section style={{
        width: '90%',
        backgroundColor: 'rgb(221, 220, 220)',
        border: '2px solid rgb(117, 117, 117)',
        borderRadius: '20px',
        padding: '30px',
        margin: '0 auto',
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
        minHeight: '400px'
      }}>
        {/* Header section */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          width: '100%',
          marginBottom: '20px'
        }}>
          <h2 style={{
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: 'black',
            margin: 0
          }}>
            Apartment Types
          </h2>
        </div>

        {/* Add new type section */}
        <div style={{
          display: 'flex',
          gap: '12px',
          alignItems: 'center',
          marginBottom: '30px',
          padding: '20px',
          backgroundColor: 'white',
          borderRadius: '12px',
          border: '2px solid #d1d5db'
        }}>
          <input
            type="text"
            value={newTypeName}
            onChange={(e) => setNewTypeName(e.target.value)}
            placeholder="Enter new apartment type (e.g., Studio, F2, F3, Duplex)"
            style={{
              flex: 1,
              padding: '12px 16px',
              border: '2px solid #d1d5db',
              borderRadius: '8px',
              fontSize: '14px',
              fontWeight: '500',
              color: '#374151',
              outline: 'none',
              transition: 'all 0.2s ease'
            }}
            onKeyPress={(e) => {
              if (e.key === 'Enter' && !isSubmitting) {
                handleAddType();
              }
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#3b82f6';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = '#d1d5db';
            }}
          />
          <button
            onClick={handleAddType}
            disabled={isSubmitting || !newTypeName.trim()}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: isSubmitting || !newTypeName.trim() ? '#f3f4f6' : '#3b82f6',
              border: 'none',
              borderRadius: '8px',
              padding: '12px 20px',
              fontSize: '14px',
              fontWeight: '600',
              color: 'white',
              cursor: isSubmitting || !newTypeName.trim() ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              if (!isSubmitting && newTypeName.trim()) {
                e.target.style.backgroundColor = '#2563eb';
              }
            }}
            onMouseLeave={(e) => {
              if (!isSubmitting && newTypeName.trim()) {
                e.target.style.backgroundColor = '#3b82f6';
              }
            }}
          >
            {isSubmitting ? (
              <>
                <div style={{
                  width: '16px',
                  height: '16px',
                  border: '2px solid #e5e7eb',
                  borderTop: '2px solid #ffffff',
                  borderRadius: '50%',
                  animation: 'spin 1s linear infinite'
                }} />
                Adding...
              </>
            ) : (
              <>
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <path d="M12 5v14M5 12h14" />
                </svg>
                Add Type
              </>
            )}
          </button>
        </div>

        {/* Types list */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '12px'
        }}>
          {loading.apartmentTypes ? (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '12px',
              color: '#6b7280',
              padding: '40px'
            }}>
              <div style={{
                width: '24px',
                height: '24px',
                border: '2px solid #e5e7eb',
                borderTop: '2px solid #3b82f6',
                borderRadius: '50%',
                animation: 'spin 1s linear infinite'
              }} />
              Loading apartment types...
            </div>
          ) : apartmentTypes.length === 0 ? (
            <div style={{
              textAlign: 'center',
              color: '#6b7280',
              padding: '40px',
              fontSize: '16px'
            }}>
              No apartment types found. Add your first apartment type above.
            </div>
          ) : (
            apartmentTypes.map((apartmentType) => (
              <div
                key={apartmentType.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '16px 20px',
                  backgroundColor: 'white',
                  borderRadius: '12px',
                  border: '2px solid #d1d5db',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = '#9ca3af';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = '#d1d5db';
                }}
              >
                {editingType?.id === apartmentType.id ? (
                  <>
                    <input
                      type="text"
                      value={editTypeName}
                      onChange={(e) => setEditTypeName(e.target.value)}
                      style={{
                        flex: 1,
                        padding: '8px 12px',
                        border: '2px solid #d1d5db',
                        borderRadius: '6px',
                        fontSize: '14px',
                        fontWeight: '500',
                        color: '#374151',
                        outline: 'none',
                        marginRight: '12px'
                      }}
                      onKeyPress={(e) => {
                        if (e.key === 'Enter' && !isSubmitting) {
                          handleUpdateType();
                        }
                        if (e.key === 'Escape') {
                          handleCancelEdit();
                        }
                      }}
                      autoFocus
                    />
                    <div style={{
                      display: 'flex',
                      gap: '8px'
                    }}>
                      <button
                        onClick={handleUpdateType}
                        disabled={isSubmitting}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          backgroundColor: '#10b981',
                          border: 'none',
                          borderRadius: '6px',
                          padding: '8px 12px',
                          fontSize: '12px',
                          fontWeight: '600',
                          color: 'white',
                          cursor: isSubmitting ? 'not-allowed' : 'pointer'
                        }}
                      >
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        >
                          <path d="M20 6 9 17l-5-5" />
                        </svg>
                        Save
                      </button>
                      <button
                        onClick={handleCancelEdit}
                        disabled={isSubmitting}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          backgroundColor: '#6b7280',
                          border: 'none',
                          borderRadius: '6px',
                          padding: '8px 12px',
                          fontSize: '12px',
                          fontWeight: '600',
                          color: 'white',
                          cursor: isSubmitting ? 'not-allowed' : 'pointer'
                        }}
                      >
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        >
                          <path d="M18 6 6 18M6 6l12 12" />
                        </svg>
                        Cancel
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '12px',
                      flex: 1
                    }}>
                      <div style={{
                        width: '8px',
                        height: '8px',
                        backgroundColor: '#10b981',
                        borderRadius: '50%'
                      }} />
                      <span style={{
                        fontSize: '16px',
                        fontWeight: '600',
                        color: '#374151'
                      }}>
                        {apartmentType.name}
                      </span>
                      <span style={{
                        fontSize: '12px',
                        color: '#6b7280',
                        backgroundColor: '#f3f4f6',
                        padding: '2px 8px',
                        borderRadius: '12px'
                      }}>
                        ID: {apartmentType.id.substring(0, 8)}...
                      </span>
                    </div>
                    <div style={{
                      display: 'flex',
                      gap: '8px'
                    }}>
                      <button
                        onClick={() => handleEditType(apartmentType)}
                        disabled={isSubmitting}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          backgroundColor: '#f59e0b',
                          border: 'none',
                          borderRadius: '6px',
                          padding: '8px 12px',
                          fontSize: '12px',
                          fontWeight: '600',
                          color: 'white',
                          cursor: isSubmitting ? 'not-allowed' : 'pointer',
                          transition: 'all 0.2s ease'
                        }}
                        onMouseEnter={(e) => {
                          if (!isSubmitting) e.target.style.backgroundColor = '#d97706';
                        }}
                        onMouseLeave={(e) => {
                          if (!isSubmitting) e.target.style.backgroundColor = '#f59e0b';
                        }}
                      >
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        >
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                          <path d="m18.5 2.5 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                        </svg>
                        Edit
                      </button>
                      <button
                        onClick={() => handleDeleteType(apartmentType)}
                        disabled={isSubmitting}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                          backgroundColor: '#ef4444',
                          border: 'none',
                          borderRadius: '6px',
                          padding: '8px 12px',
                          fontSize: '12px',
                          fontWeight: '600',
                          color: 'white',
                          cursor: isSubmitting ? 'not-allowed' : 'pointer',
                          transition: 'all 0.2s ease'
                        }}
                        onMouseEnter={(e) => {
                          if (!isSubmitting) e.target.style.backgroundColor = '#dc2626';
                        }}
                        onMouseLeave={(e) => {
                          if (!isSubmitting) e.target.style.backgroundColor = '#ef4444';
                        }}
                      >
                        <svg
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                        >
                          <path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m3 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6h14Z" />
                          <path d="M10 11v6M14 11v6" />
                        </svg>
                        Delete
                      </button>
                    </div>
                  </>
                )}
              </div>
            ))
          )}
        </div>

        {/* Error display */}
        {error && (
          <div style={{
            color: '#ef4444',
            marginTop: '20px',
            padding: '16px',
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            borderRadius: '12px',
            border: '2px solid rgba(239, 68, 68, 0.2)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between'
          }}>
            <span>Error: {error}</span>
            <button
              onClick={clearError}
              style={{
                backgroundColor: 'transparent',
                border: 'none',
                color: '#ef4444',
                cursor: 'pointer',
                padding: '4px',
                borderRadius: '4px'
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M18 6 6 18M6 6l12 12" />
              </svg>
            </button>
          </div>
        )}
      </section>

      {/* Add CSS animation */}
      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default ApartmentTypePage;
