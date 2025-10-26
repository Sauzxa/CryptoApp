import React, { useState, useRef, useEffect } from 'react';
import { useData } from '../hooks/useData';
import { useApartmentTypes } from '../contexts/ApartmentTypeContext';
import { uploadImage, createPreview, cleanupPreview, validateImage } from '../utils/imageUpload';

const FyhImageEditor = ({ divId = 1 }) => {
    const { 
        dashboardDivs, 
        loading, 
        fetchDashboardDivs, 
        updateDashboardDivData 
    } = useData();

    const {
        apartmentTypes,
        fetchApartmentTypes,
        addApartmentType
    } = useApartmentTypes();

    const [selectedImage, setSelectedImage] = useState('/download.png');
    const [price, setPrice] = useState('');
    const [appartement, setAppartement] = useState('');
    const [isAddingOption, setIsAddingOption] = useState(false);
    const [newOption, setNewOption] = useState('');
    const [isHovered, setIsHovered] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [isUploading, setIsUploading] = useState(false);

    const fileInputRef = useRef(null);

    // Load dashboard divs data on component mount
    useEffect(() => {
        fetchDashboardDivs();
    }, [fetchDashboardDivs]);

    // Load apartment types on component mount
    useEffect(() => {
        fetchApartmentTypes();
    }, [fetchApartmentTypes]);

    // Update local state when dashboard divs data is loaded
    useEffect(() => {
        const currentDiv = dashboardDivs.find(div => div.id === divId);
        if (currentDiv) {
            setSelectedImage(currentDiv.photoUrl || '/download.png');
            setPrice(currentDiv.price ? currentDiv.price.toString() : '');
            setAppartement(currentDiv.apartment || '');
        }
    }, [dashboardDivs, divId]);

    const handleImageClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = async (event) => {
        const file = event.target.files[0];
        if (!file) return;

        // Validate file
        const validation = validateImage(file);
        if (!validation.isValid) {
            alert(validation.error);
            return;
        }

        // Create preview immediately
        const previewUrl = createPreview(file);
        setSelectedImage(previewUrl);

        // Upload to Cloudinary
        setIsUploading(true);
        
        try {
            const cloudinaryUrl = await uploadImage(file);
            
            // Replace preview with Cloudinary URL
            cleanupPreview(previewUrl);
            setSelectedImage(cloudinaryUrl);
            
        } catch (error) {
            alert('Failed to upload image: ' + error.message);
            // Revert to previous image
            cleanupPreview(previewUrl);
            const currentDiv = dashboardDivs.find(div => div.id === divId);
            setSelectedImage(currentDiv?.photoUrl || '/download.png');
        } finally {
            setIsUploading(false);
        }
    };

    const handleAddOption = async () => {
        if (newOption.trim()) {
            // Check if apartment type already exists
            const existingType = apartmentTypes.find(type => 
                type.name.toLowerCase() === newOption.trim().toLowerCase()
            );
            
            if (existingType) {
                alert('This apartment type already exists');
                return;
            }

            try {
                const result = await addApartmentType(newOption.trim());
                if (result.success) {
                    setAppartement(result.data.name);
                    setNewOption('');
                    setIsAddingOption(false);
                } else {
                    alert('Failed to add apartment type: ' + result.error);
                }
            } catch (error) {
                alert('Error adding apartment type: ' + error.message);
            }
        }
    };

    const handleCancelAdd = () => {
        setNewOption('');
        setIsAddingOption(false);
    };

    // Save data to backend
    const handleSave = async () => {
        if (!selectedImage || !price || !appartement) {
            alert('Please fill in all fields before saving');
            return;
        }

        setIsSaving(true);
        try {
            const divData = {
                photoUrl: selectedImage,
                price: parseInt(price),
                apartment: appartement
            };

            const result = await updateDashboardDivData(divId, divData);
            if (result.success) {
                alert('Dashboard updated successfully!');
            } else {
                alert('Failed to update dashboard: ' + result.error);
            }
        } catch (error) {
            alert('Error saving data: ' + error.message);
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div style={{
            backgroundColor: 'white',
            border: '1px solid rgba(0, 0, 0, 0.32)',
            borderRadius: '12px',
            padding: '20px',
            width: '300px',
            display: 'flex',
            flexDirection: 'column',
            gap: '16px'
        }}>
            {/* Image Section */}
            <div
                onClick={handleImageClick}
                onMouseEnter={() => setIsHovered(true)}
                onMouseLeave={() => setIsHovered(false)}
                style={{
                    width: '100%',
                    height: '200px',
                    cursor: 'pointer',
                    borderRadius: '8px',
                    overflow: 'hidden',
                    border: '2px dashed #d1d5db',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    position: 'relative'
                }}
            >
                <img
                    src={selectedImage}
                    alt="Property"
                    style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                        transition: 'filter 0.3s ease'
                    }}
                />

                {/* Hover overlay */}
                <div
                    style={{
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundColor: 'rgba(0, 0, 0, 0.6)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexDirection: 'column',
                        gap: '8px',
                        opacity: isHovered || isUploading ? 1 : 0,
                        transition: 'opacity 0.3s ease',
                        color: 'white',
                        fontSize: '16px',
                        fontWeight: '600',
                        pointerEvents: 'none'
                    }}
                >
                    {isUploading ? (
                        <>
                            <div style={{
                                width: '32px',
                                height: '32px',
                                border: '3px solid rgba(255, 255, 255, 0.3)',
                                borderTop: '3px solid white',
                                borderRadius: '50%',
                                animation: 'spin 1s linear infinite'
                            }} />
                            <div>Uploading...</div>
                        </>
                    ) : (
                        'Edit Image'
                    )}
                </div>
            </div>

            {/* Hidden file input */}
            <input
                type="file"
                accept="image/*"
                ref={fileInputRef}
                onChange={handleFileChange}
                style={{ display: 'none' }}
            />

            {/* Price Input */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <label style={{
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                }}>
                    Price
                </label>
                <input
                    type="text"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    style={{
                        padding: '10px 12px',
                        border: '1px solid #d1d5db',
                        borderRadius: '6px',
                        fontSize: '14px',
                        backgroundColor: '#f9fafb',
                        outline: 'none'
                    }}
                />
            </div>

            {/* Appartement Select */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <label style={{
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                }}>
                    Appartement
                </label>

                {!isAddingOption ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <select
                            value={appartement}
                            onChange={(e) => setAppartement(e.target.value)}
                            style={{
                                padding: '10px 12px',
                                border: '1px solid #d1d5db',
                                borderRadius: '6px',
                                fontSize: '14px',
                                backgroundColor: '#f9fafb',
                                outline: 'none',
                                width: '100%'
                            }}
                        >
                            <option value="">Select apartment type</option>
                            {apartmentTypes.map((type) => (
                                <option key={type.id} value={type.name}>
                                    {type.name}
                                </option>
                            ))}
                        </select>
                        <button
                            onClick={() => setIsAddingOption(true)}
                            style={{
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
                                transition: 'all 0.2s ease',
                                alignSelf: 'center'
                                , marginTop: '15px'
                            }}
                            onMouseEnter={(e) => {
                                e.target.style.backgroundColor = '#f9fafb';
                                e.target.style.borderColor = '#9ca3af';
                            }}
                            onMouseLeave={(e) => {
                                e.target.style.backgroundColor = 'white';
                                e.target.style.borderColor = '#d1d5db';
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
                                <path d="M12 5v14m-7-7h14" />
                            </svg>
                            Add More
                        </button>
                    </div>
                ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <input
                            type="text"
                            value={newOption}
                            onChange={(e) => setNewOption(e.target.value)}
                            placeholder="Enter new option"
                            style={{
                                padding: '10px 12px',
                                border: '1px solid #d1d5db',
                                borderRadius: '6px',
                                fontSize: '14px',
                                backgroundColor: '#f9fafb',
                                outline: 'none',
                                width: '100%'
                            }}
                        />
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                            <button
                                onClick={handleAddOption}
                                style={{
                                    padding: '8px 12px',
                                    backgroundColor: '#10b981',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '6px',
                                    fontSize: '12px',
                                    cursor: 'pointer'
                                }}
                            >
                                Add
                            </button>
                            <button
                                onClick={handleCancelAdd}
                                style={{
                                    padding: '8px 12px',
                                    backgroundColor: '#ef4444',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '6px',
                                    fontSize: '12px',
                                    cursor: 'pointer'
                                }}
                            >
                                Cancel
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* Save Button */}
            <button
                onClick={handleSave}
                disabled={isSaving || loading.dashboardDivs}
                style={{
                    width: '100%',
                    backgroundColor: isSaving ? '#9ca3af' : '#10b981',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    padding: '12px',
                    fontSize: '14px',
                    fontWeight: '600',
                    cursor: isSaving ? 'not-allowed' : 'pointer',
                    transition: 'background-color 0.2s ease',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '8px'
                }}
                onMouseEnter={(e) => {
                    if (!isSaving) {
                        e.target.style.backgroundColor = '#059669';
                    }
                }}
                onMouseLeave={(e) => {
                    if (!isSaving) {
                        e.target.style.backgroundColor = '#10b981';
                    }
                }}
            >
                {isSaving ? (
                    <>
                        <div style={{
                            width: '16px',
                            height: '16px',
                            border: '2px solid #ffffff',
                            borderTop: '2px solid transparent',
                            borderRadius: '50%',
                            animation: 'spin 1s linear infinite'
                        }} />
                        Saving...
                    </>
                ) : (
                    'Save Changes'
                )}
            </button>
        </div>
    );
};

export default FyhImageEditor;
