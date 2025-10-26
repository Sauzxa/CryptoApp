import React, { useState, useEffect, useCallback } from 'react';
import { useData } from '../hooks/useData';
import { useAuth } from '../contexts/AuthContext';
import FyhImageEditor from '../components/FyhImageEditor';
import BestSellerImageEditor from '../components/BestSellerImageEditor';
import HeroStatEditor from '../components/HeroStatEditor';

const ImagesPage = () => {
  const { regions, loading, error, fetchRegions, addRegion, addApartment, updateApartmentData, deleteApartmentData, deleteRegionData } = useData();
  const { isAuthenticated } = useAuth();
  
  const [selectedRegion, setSelectedRegion] = useState('');
  const [selectedRegionData, setSelectedRegionData] = useState(null);
  const [isAddingRegion, setIsAddingRegion] = useState(false);
  const [newRegion, setNewRegion] = useState('');
  const [apartments, setApartments] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isRegionDropdownOpen, setIsRegionDropdownOpen] = useState(false);
  const [regionDropdownRef, setRegionDropdownRef] = useState(null);

  // Load regions on component mount
  useEffect(() => {
    if (isAuthenticated) {
      fetchRegions();
    }
  }, [isAuthenticated, fetchRegions]);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (regionDropdownRef && !regionDropdownRef.contains(event.target)) {
        setIsRegionDropdownOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [regionDropdownRef]);

  // Update selected region data when regions change or selection changes
  useEffect(() => {
    if (selectedRegion && regions.length > 0) {
      const regionData = regions.find(r => r.id === selectedRegion);
      setSelectedRegionData(regionData);
      setApartments(regionData?.apartments || []);
    } else {
      setSelectedRegionData(null);
      setApartments([]);
    }
  }, [selectedRegion, regions]);

  const handleAddRegion = async () => {
    if (newRegion.trim()) {
      try {
        console.log('🔄 Creating region:', newRegion.trim());
        const result = await addRegion(newRegion.trim());
        console.log('📤 Region creation result:', result);
        
        if (result && result.success) {
          console.log('✅ Region created successfully:', result.data);
          setSelectedRegion(result.data.id);
          setNewRegion('');
          setIsAddingRegion(false);
          // Refresh the regions list
          fetchRegions();
        } else {
          console.error('❌ Region creation failed:', result);
          alert('Failed to create region: ' + (result?.error || 'Unknown error'));
        }
      } catch (error) {
        console.error('❌ Region creation error:', error);
        alert('Error creating region: ' + error.message);
      }
    }
  };

  const handleCancelAddRegion = () => {
    setNewRegion('');
    setIsAddingRegion(false);
  };

  const handleDeleteRegion = async () => {
    if (selectedRegion) {
      if (window.confirm('Are you sure you want to delete this region? This will delete all apartments in this region. This action cannot be undone.')) {
        try {
          console.log('🔄 Deleting region:', selectedRegion);
          const result = await deleteRegionData(selectedRegion);
          
          if (result && result.success) {
            console.log('✅ Region deleted successfully');
            setSelectedRegion('');
            setApartments([]);
            // Refresh the regions list
            fetchRegions();
            alert('Region deleted successfully!');
          } else {
            console.error('❌ Region deletion failed:', result);
            alert('Failed to delete region: ' + (result?.error || 'Unknown error'));
          }
        } catch (error) {
          console.error('❌ Region deletion error:', error);
          alert('Error deleting region: ' + error.message);
        }
      }
    } else {
      alert('Please select a region first');
    }
  };

  const toggleRegionDropdown = () => {
    if (!loading.regions) {
      setIsRegionDropdownOpen(!isRegionDropdownOpen);
    }
  };

  const handleRegionSelect = (regionId) => {
    setSelectedRegion(regionId);
    setIsRegionDropdownOpen(false);
  };

  const updateLocalApartmentData = useCallback((index, apartmentData) => {
    setApartments(prev => {
      const updated = [...prev];
      updated[index] = apartmentData;
      return updated;
    });
  }, []);

  const handleDeleteApartment = useCallback(async (index) => {
    const apartment = apartments[index];
    
    // If apartment has an ID, it exists in the backend and needs to be deleted
    if (apartment.id && selectedRegion) {
      if (window.confirm('Are you sure you want to delete this apartment? This action cannot be undone.')) {
        try {
          const result = await deleteApartmentData(selectedRegion, apartment.id);
          if (result.success) {
            // Remove from local state
            setApartments(prev => {
              const updated = [...prev];
              updated.splice(index, 1);
              return updated;
            });
            alert('Apartment deleted successfully!');
          } else {
            alert('Failed to delete apartment. Please try again.');
          }
        } catch (error) {
          console.error('Error deleting apartment:', error);
          alert('Error deleting apartment: ' + error.message);
        }
      }
    } else {
      // New apartment (no ID), just remove from local state
      setApartments(prev => {
        const updated = [...prev];
        updated.splice(index, 1);
        return updated;
      });
    }
  }, [apartments, selectedRegion, deleteApartmentData]);

  const handleConfirmBestSellers = async () => {
    if (!selectedRegion) {
      alert('Please select a region first');
      return;
    }

    if (apartments.length === 0) {
      alert('Please add at least one apartment');
      return;
    }

    // Validate that all apartments have required data
    const invalidApartments = apartments.filter((apt) => 
      !apt.imageUrl || !apt.description || !apt.types || apt.types.length === 0
    );

    if (invalidApartments.length > 0) {
      const missingInfo = invalidApartments.map((apt) => {
        const issues = [];
        if (!apt.imageUrl) issues.push('image');
        if (!apt.description) issues.push('description');
        if (!apt.types || apt.types.length === 0) issues.push('apartment type');
        return `Apartment ${apartments.indexOf(apt) + 1}: ${issues.join(', ')}`;
      }).join('\n');
      
      alert(`Please complete the following apartment information before saving:\n\n${missingInfo}`);
      return;
    }

    setIsSubmitting(true);
    try {
      // Check if we're creating a new region or updating existing one
      const isNewRegion = !selectedRegionData;
      
      let targetRegionId = selectedRegion;
      
      // If it's a new region, create it first
      if (isNewRegion && newRegion.trim()) {
        const regionResult = await addRegion(newRegion.trim());
        if (!regionResult.success) {
          throw new Error(regionResult.error || 'Failed to create region');
        }
        targetRegionId = regionResult.data.id;
      }

      // Process only valid apartments (filter out incomplete ones)
      const validApartments = apartments.filter(apt => 
        apt.imageUrl && apt.description && apt.types?.length > 0
      );

      // Keep track of processed apartments to avoid duplication
      const processedApartments = [];

      for (const apartment of validApartments) {
        const apartmentData = {
          imageUrl: apartment.imageUrl,
          description: apartment.description,
          // Ensure types are sent as an array of strings (names), not objects
          types: Array.isArray(apartment.types) 
            ? apartment.types.map(type => typeof type === 'string' ? type : type.name || type)
            : []
        };
        
        // Check if this is an existing apartment (has an ID) or a new one
        if (apartment.id) {
          // This is an existing apartment - use update endpoint
          console.log(`🔄 Updating existing apartment ${apartment.id} in region ${targetRegionId}`);
          const result = await updateApartmentData(targetRegionId, apartment.id, apartmentData);
          if (!result.success) {
            throw new Error(`Failed to update apartment: ${result.error || 'Unknown error'}`);
          }
          console.log(`✅ Successfully updated apartment ${apartment.id}`);
          processedApartments.push({ ...apartment, ...apartmentData });
        } else {
          // This is a new apartment - use add endpoint
          console.log(`➕ Adding new apartment to region ${targetRegionId}`);
          const result = await addApartment(targetRegionId, apartmentData);
          if (!result.success) {
            throw new Error(`Failed to add apartment: ${result.error || 'Unknown error'}`);
          }
          console.log(`✅ Successfully added new apartment with ID:`, result.data?.id);
          // Add the returned apartment data (with ID) to processed list
          processedApartments.push(result.data || { ...apartmentData, id: `temp-${Date.now()}` });
        }
      }
      
      alert('Best sellers updated successfully!');
      
      // Update local state with processed apartments (prevents showing stale data)
      setApartments(processedApartments);
      
      // Refresh regions to show updated data from server
      await fetchRegions();
      
    } catch (error) {
      alert('Error updating best sellers: ' + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div style={{
      padding: '40px',
      textAlign: 'center',
      color: 'white'
    }}>
      <div style={{
        marginBottom: '40px'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          marginBottom: '10px',
          fontWeight: 'bold',
          color: 'white'
        }}>
          Find Your Home Images
        </h1>
        <p style={{
          fontSize: '1.2rem',
          opacity: 0.9,
          color: 'white',
          margin: 0
        }}>
          Manage your featured Properties in the find your home images
        </p>
      </div>

      {/* Main content section */}
      <section style={{
        width: '90%',
        backgroundColor: 'rgb(221, 220, 220) ',
        border: '2px solid rgb(117, 117, 117)',
        borderRadius: '20px',
        padding: '30px',
        margin: '0 auto',
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
        minHeight: '400px'
      }}>
        {/* Header section with title and edit button */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          width: '100%'
        }}>
          <h2 style={{
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: 'black',
            margin: 0
          }}>
            Editing FYH Section
          </h2>

          <button style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: 'white',
            border: '2px solid #d1d5db',
            borderRadius: '8px',
            padding: '8px 16px',
            fontSize: '14px',
            fontWeight: '600',
            color: '#374151',
            cursor: 'pointer',
            transition: 'all 0.2s ease'
          }}
            onMouseEnter={(e) => {
              e.target.style.backgroundColor = '#f9fafb';
              e.target.style.borderColor = '#9ca3af';
            }}
            onMouseLeave={(e) => {
              e.target.style.backgroundColor = 'white';
              e.target.style.borderColor = '#d1d5db';
            }}>
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
              <path d="m18.5 2.5 3 3L12 15l-4 1 1-4 9.5-9.5z" />
            </svg>
            confirm
          </button>
        </div>

        {/* Image Editor Section */}
        <div style={{
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          width: '100%'
        }}>
          <FyhImageEditor divId={1} />
          <FyhImageEditor divId={2} />
          <FyhImageEditor divId={3} />
        </div>
      </section>

      {/* Our Best Seller Images Header */}
      <div style={{
        marginTop: '60px',
        marginBottom: '40px',
        textAlign: 'center'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          marginBottom: '10px',
          fontWeight: 'bold',
          color: 'white'
        }}>
          Our Best Seller Images
        </h1>
        <p style={{
          fontSize: '1.2rem',
          opacity: 0.9,
          color: 'white',
          margin: 0
        }}>
          Manage your featured Properties in the Carousal images
        </p>
      </div>

      {/* Best Seller Options Section */}
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
        minHeight: '200px'
      }}>
        {/* Header section with title and controls */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          width: '100%'
        }}>
          <h2 style={{
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: 'black',
            margin: 0
          }}>
            Editing Best Seller Options
          </h2>

          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}>
            {/* Region Dropdown */}
            <div style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '4px'
            }}>
              <label style={{
                fontSize: '12px',
                fontWeight: '600',
                color: '#374151',
                textAlign: 'left'
              }}>
                Region:
              </label>
              
              {!isAddingRegion ? (
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}>
                  {/* Custom Region Dropdown */}
                  <div style={{ position: 'relative' }} ref={setRegionDropdownRef}>
                    {/* Hidden input for form validation */}
                    <input
                      type="hidden"
                      name="selectedRegion"
                      value={selectedRegion}
                    />
                    {/* Dropdown Button */}
                    <div
                      onClick={toggleRegionDropdown}
                      style={{
                        width: '180px',
                        padding: '12px 16px',
                        paddingRight: '40px',
                        border: `1px solid ${isRegionDropdownOpen ? '#3B82F6' : '#d1d5db'}`,
                        borderRadius: '8px',
                        fontSize: '14px',
                        fontWeight: '500',
                        backgroundColor: 'white',
                        color: !selectedRegion ? '#9ca3af' : '#374151',
                        outline: 'none',
                        cursor: loading.regions ? 'not-allowed' : 'pointer',
                        transition: 'all 0.2s ease',
                        opacity: loading.regions ? 0.7 : 1,
                        boxShadow: isRegionDropdownOpen ? '0 0 0 3px rgba(59, 130, 246, 0.1)' : 'none'
                      }}
                      onMouseEnter={(e) => {
                        if (!loading.regions && !isRegionDropdownOpen) {
                          e.target.style.borderColor = '#9ca3af';
                        }
                      }}
                      onMouseLeave={(e) => {
                        if (!loading.regions && !isRegionDropdownOpen) {
                          e.target.style.borderColor = '#d1d5db';
                        }
                      }}
                    >
                      <span style={{ 
                        display: 'block', 
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap'
                      }}>
                        {loading.regions 
                          ? 'Loading regions...' 
                          : selectedRegion ? regions.find(r => r.id === selectedRegion)?.name || 'Select Region' : 'Select Region'
                        }
                      </span>
                    </div>
                    
                    {/* Dropdown Arrow */}
                    <div style={{
                      position: 'absolute',
                      top: '50%',
                      right: '12px',
                      transform: 'translateY(-50%)',
                      pointerEvents: 'none',
                      display: 'flex',
                      alignItems: 'center'
                    }}>
                      {loading.regions ? (
                        <div style={{
                          width: '16px',
                          height: '16px',
                          border: '2px solid #e5e7eb',
                          borderTop: '2px solid #3b82f6',
                          borderRadius: '50%',
                          animation: 'spin 1s linear infinite'
                        }} />
                      ) : (
                        <svg
                          style={{
                            width: '20px',
                            height: '20px',
                            transition: 'all 0.2s ease',
                            transform: isRegionDropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                            color: '#9ca3af'
                          }}
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
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
                    {isRegionDropdownOpen && !loading.regions && regions.length > 0 && (
                      <div style={{
                        position: 'absolute',
                        zIndex: 50,
                        width: '100%',
                        marginTop: '4px',
                        backgroundColor: 'white',
                        border: '1px solid #d1d5db',
                        borderRadius: '8px',
                        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
                        maxHeight: '240px',
                        overflowY: 'auto'
                      }}>
                        {/* Empty option */}
                        <div
                          onClick={() => handleRegionSelect('')}
                          style={{
                            padding: '12px 16px',
                            cursor: 'pointer',
                            fontSize: '14px',
                            transition: 'all 0.15s ease',
                            backgroundColor: !selectedRegion ? '#eff6ff' : 'transparent',
                            color: !selectedRegion ? '#1d4ed8' : '#374151',
                            fontWeight: !selectedRegion ? '600' : '500',
                            borderBottom: '1px solid #f3f4f6'
                          }}
                          onMouseEnter={(e) => {
                            if (selectedRegion) {
                              e.target.style.backgroundColor = '#f9fafb';
                              e.target.style.color = '#1d4ed8';
                            }
                          }}
                          onMouseLeave={(e) => {
                            if (selectedRegion) {
                              e.target.style.backgroundColor = 'transparent';
                              e.target.style.color = '#374151';
                            }
                          }}
                        >
                          <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between'
                          }}>
                            <span style={{ 
                              display: 'block',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap'
                            }}>
                              Select Region
                            </span>
                            {!selectedRegion && (
                              <svg
                                style={{
                                  width: '16px',
                                  height: '16px',
                                  color: '#1d4ed8'
                                }}
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
                        
                        {/* Region options */}
                        {regions.map((region, index) => (
                          <div
                            key={region.id}
                            onClick={() => handleRegionSelect(region.id)}
                            style={{
                              padding: '12px 16px',
                              cursor: 'pointer',
                              fontSize: '14px',
                              transition: 'all 0.15s ease',
                              backgroundColor: selectedRegion === region.id ? '#eff6ff' : 'transparent',
                              color: selectedRegion === region.id ? '#1d4ed8' : '#374151',
                              fontWeight: selectedRegion === region.id ? '600' : '500',
                              borderBottom: index === regions.length - 1 ? 'none' : '1px solid #f3f4f6',
                              borderRadius: index === regions.length - 1 ? '0 0 6px 6px' : '0'
                            }}
                            onMouseEnter={(e) => {
                              if (selectedRegion !== region.id) {
                                e.target.style.backgroundColor = '#f9fafb';
                                e.target.style.color = '#1d4ed8';
                              }
                            }}
                            onMouseLeave={(e) => {
                              if (selectedRegion !== region.id) {
                                e.target.style.backgroundColor = 'transparent';
                                e.target.style.color = '#374151';
                              }
                            }}
                          >
                            <div style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between'
                            }}>
                              <span style={{ 
                                display: 'block',
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap'
                              }}>
                                {region.name}
                              </span>
                              {selectedRegion === region.id && (
                                <svg
                                  style={{
                                    width: '16px',
                                    height: '16px',
                                    color: '#1d4ed8'
                                  }}
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
                    {isRegionDropdownOpen && !loading.regions && regions.length === 0 && (
                      <div style={{
                        position: 'absolute',
                        zIndex: 50,
                        width: '100%',
                        marginTop: '4px',
                        backgroundColor: 'white',
                        border: '1px solid #d1d5db',
                        borderRadius: '8px',
                        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)'
                      }}>
                        <div style={{
                          padding: '12px 16px',
                          fontSize: '14px',
                          color: '#6b7280',
                          textAlign: 'center'
                        }}>
                          No regions available
                        </div>
                      </div>
                    )}
                  </div>
                  
                  {/* Add Region Button */}
                  <button
                    onClick={() => setIsAddingRegion(true)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      backgroundColor: 'white',
                      border: '2px solid #d1d5db',
                      borderRadius: '8px',
                      padding: '8px',
                      fontSize: '14px',
                      fontWeight: '600',
                      color: '#374151',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease',
                      minWidth: '36px',
                      height: '36px',
                      marginRight: '5px'
                    }}
                    onMouseEnter={(e) => {
                      e.target.style.backgroundColor = '#f9fafb';
                      e.target.style.borderColor = '#9ca3af';
                    }}
                    onMouseLeave={(e) => {
                      e.target.style.backgroundColor = 'white';
                      e.target.style.borderColor = '#d1d5db';
                    }}
                    title="Add new region"
                  >
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
                  </button>
                  
                  {/* Delete Region Button */}
                  <button
                    onClick={handleDeleteRegion}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      backgroundColor: selectedRegion ? 'white' : '#f3f4f6',
                      border: '2px solid #d1d5db',
                      borderRadius: '8px',
                      padding: '8px',
                      fontSize: '14px',
                      fontWeight: '600',
                      color: selectedRegion ? '#ef4444' : '#9ca3af',
                      cursor: selectedRegion ? 'pointer' : 'not-allowed',
                      transition: 'all 0.2s ease',
                      minWidth: '36px',
                      height: '36px'
                    }}
                    onMouseEnter={(e) => {
                      if (selectedRegion) {
                        e.target.style.backgroundColor = '#fee2e2';
                        e.target.style.borderColor = '#ef4444';
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (selectedRegion) {
                        e.target.style.backgroundColor = 'white';
                        e.target.style.borderColor = '#d1d5db';
                      }
                    }}
                    disabled={!selectedRegion}
                    title={selectedRegion ? "Delete selected region" : "Select a region to delete"}
                  >
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <path d="M5 12h14" />
                    </svg>
                  </button>
                </div>
              ) : (
                <div style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px'
                }}>
                  <input
                    type="text"
                    value={newRegion}
                    onChange={(e) => setNewRegion(e.target.value)}
                    placeholder="Enter new region"
                    style={{
                      padding: '8px 12px',
                      border: '2px solid #d1d5db',
                      borderRadius: '8px',
                      fontSize: '14px',
                      fontWeight: '600',
                      backgroundColor: 'white',
                      color: '#374151',
                      outline: 'none',
                      minWidth: '120px'
                    }}
                    onKeyPress={(e) => {
                      if (e.key === 'Enter') {
                        handleAddRegion();
                      }
                    }}
                  />
                  <div style={{
                    display: 'flex',
                    gap: '6px',
                    justifyContent: 'center'
                  }}>
                    <button
                      onClick={handleAddRegion}
                      style={{
                        backgroundColor: 'white',
                        border: '2px solid #d1d5db',
                        borderRadius: '6px',
                        padding: '4px 8px',
                        fontSize: '12px',
                        fontWeight: '600',
                        color: '#374151',
                        cursor: 'pointer'
                      }}
                    >
                      Add
                    </button>
                    <button
                      onClick={handleCancelAddRegion}
                      style={{
                        backgroundColor: 'white',
                        border: '2px solid #d1d5db',
                        borderRadius: '6px',
                        padding: '4px 8px',
                        fontSize: '12px',
                        fontWeight: '600',
                        color: '#374151',
                        cursor: 'pointer'
                      }}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Confirm Button */}
            <button 
              onClick={handleConfirmBestSellers}
              disabled={isSubmitting || !selectedRegion}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                backgroundColor: isSubmitting || !selectedRegion ? '#f3f4f6' : 'white',
                border: '2px solid #d1d5db',
                borderRadius: '8px',
                padding: '8px 16px',
                fontSize: '14px',
                fontWeight: '600',
                color: isSubmitting || !selectedRegion ? '#9ca3af' : '#374151',
                cursor: isSubmitting || !selectedRegion ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s ease',
                marginTop: '20px'
              }}
              onMouseEnter={(e) => {
                if (!isSubmitting && selectedRegion) {
                  e.target.style.backgroundColor = '#f9fafb';
                  e.target.style.borderColor = '#9ca3af';
                }
              }}
              onMouseLeave={(e) => {
                if (!isSubmitting && selectedRegion) {
                  e.target.style.backgroundColor = 'white';
                  e.target.style.borderColor = '#d1d5db';
                }
              }}>
              {isSubmitting ? (
                <>
                  <div style={{
                    width: '16px',
                    height: '16px',
                    border: '2px solid #e5e7eb',
                    borderTop: '2px solid #3b82f6',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite'
                  }} />
                  Saving...
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
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                    <path d="m18.5 2.5 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                  </svg>
                  Confirm
                </>
              )}
            </button>
          </div>
        </div>

        {/* Best Seller Image Editors Section */}
        <div style={{
          display: 'flex',
          flexDirection: 'row',
          flexWrap: 'wrap',
          justifyContent: 'flex-start',
          gap: '20px',
          width: '100%',
          marginTop: '20px'
        }}>
          {/* Existing Apartments */}
          {apartments.map((apartment, index) => (
            <BestSellerImageEditor 
              key={apartment.id ? `apartment-${apartment.id}` : `new-apartment-${index}`}
              index={index}
              apartmentData={apartment}
              onDataChange={(data) => updateLocalApartmentData(index, data)}
              onDelete={handleDeleteApartment}
              disabled={!selectedRegion}
            />
          ))}
          
          {/* Add Apartment Button - Show when region is selected */}
          {selectedRegion && (
            <div style={{
              backgroundColor: 'white',
              border: '2px dashed #d1d5db',
              borderRadius: '12px',
              padding: '20px',
              width: '300px',
              height: '400px',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '16px',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
              ':hover': {
                borderColor: '#3b82f6',
                backgroundColor: '#f8fafc'
              }
            }}
            onClick={() => {
              // Add new empty apartment (without ID to mark as new)
              const newApartments = [...apartments, {
                imageUrl: '',
                description: '',
                types: []
                // Note: No 'id' field means this is a new apartment
              }];
              setApartments(newApartments);
            }}
            onMouseEnter={(e) => {
              e.target.style.borderColor = '#3b82f6';
              e.target.style.backgroundColor = '#f8fafc';
            }}
            onMouseLeave={(e) => {
              e.target.style.borderColor = '#d1d5db';
              e.target.style.backgroundColor = 'white';
            }}
            >
              <svg
                width="48"
                height="48"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#3b82f6"
                strokeWidth="2"
              >
                <path d="M12 5v14M5 12h14" />
              </svg>
              <div style={{
                fontSize: '18px',
                fontWeight: '600',
                color: '#3b82f6',
                textAlign: 'center'
              }}>
                Add New Apartment
              </div>
              <div style={{
                fontSize: '14px',
                color: '#6b7280',
                textAlign: 'center',
                lineHeight: '1.4'
              }}>
                Click to add a new apartment to this region<br/>
                ({apartments.length} apartments in this region)
              </div>
            </div>
          )}
        </div>
        
        {/* Loading/Error states */}
        {loading.regions && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            color: '#6b7280',
            marginTop: '20px'
          }}>
            <div style={{
              width: '20px',
              height: '20px',
              border: '2px solid #e5e7eb',
              borderTop: '2px solid #3b82f6',
              borderRadius: '50%',
              animation: 'spin 1s linear infinite'
            }} />
            Loading regions...
          </div>
        )}
        
        {error && (
          <div style={{
            color: '#ef4444',
            marginTop: '20px',
            padding: '12px',
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            borderRadius: '8px',
            border: '1px solid rgba(239, 68, 68, 0.2)'
          }}>
            Error: {error}
          </div>
        )}
      </section>

      {/* Our Hero Images Header */}
      <div style={{
        marginTop: '60px',
        marginBottom: '40px',
        textAlign: 'center'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          marginBottom: '10px',
          fontWeight: 'bold',
          color: 'white'
        }}>
          Our Hero Images
        </h1>
        <p style={{
          fontSize: '1.2rem',
          opacity: 0.9,
          color: 'white',
          margin: 0
        }}>
          Manage your featured stats in the Hero image
        </p>
      </div>

      {/* Hero Section Options */}
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
        minHeight: '200px'
      }}>
        {/* Header section with title and button */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          width: '100%'
        }}>
          <h2 style={{
            fontSize: '1.5rem',
            fontWeight: 'bold',
            color: 'black',
            margin: 0
          }}>
            Editing Hero Section
          </h2>
        </div>
        {/* Hero Stat Editors (no image) */}
        <div style={{
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-between',
          width: '100%',
          flexWrap: 'wrap',
          gap: '20px'
        }}>
          <HeroStatEditor title="Properties Listed" placeholder="Enter number" fieldKey="propertiesListed" />
          <HeroStatEditor title="Happy Clients Served" placeholder="Enter number" fieldKey="happyClients" />
          <HeroStatEditor title="Days to Close a Deal" placeholder="Enter number" fieldKey="daysToClose" />
        </div>
      </section>


    </div>
  );
};

export default ImagesPage;
