import { useState, useRef, useEffect, useCallback } from 'react';
import { useApartmentTypes } from '../contexts/ApartmentTypeContext';
import { uploadImage, createPreview, cleanupPreview, validateImage } from '../utils/imageUpload';

const BestSellerImageEditor = ({ 
  index, 
  apartmentData = {}, 
  onDataChange, 
  onDelete,
  disabled = false 
}) => {
    const {
        apartmentTypes,
        fetchApartmentTypes,
        addApartmentType
    } = useApartmentTypes();

    const [selectedImage, setSelectedImage] = useState(apartmentData.imageUrl || '/download.png');
    const [description, setDescription] = useState(apartmentData.description || '');
    const [selectedTypes, setSelectedTypes] = useState(apartmentData.types || []);
    const [isAddingOption, setIsAddingOption] = useState(false);
    const [newOption, setNewOption] = useState('');
    const [isHovered, setIsHovered] = useState(false);
    const [isUploading, setIsUploading] = useState(false);
    const fileInputRef = useRef(null);

    const handleImageClick = () => {
        if (!disabled) {
            fileInputRef.current?.click();
        }
    };

    const handleFileChange = useCallback(async (event) => {
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
            const cloudinaryUrl = await uploadImage(file, 'sellers');
            
            // Replace preview with Cloudinary URL only if component is still mounted
            cleanupPreview(previewUrl);
            setSelectedImage(cloudinaryUrl);
            
        } catch (error) {
            console.error('Image upload failed:', error);
            alert('Failed to upload image: ' + error.message);
            // Revert to previous image
            cleanupPreview(previewUrl);
            setSelectedImage(apartmentData.imageUrl || '/download.png');
        } finally {
            setIsUploading(false);
        }
        
        // Clear the file input
        if (event.target) {
            event.target.value = '';
        }
    }, [apartmentData.imageUrl]);

    // Load apartment types on component mount
    useEffect(() => {
        fetchApartmentTypes();
    }, [fetchApartmentTypes]);

    // Sync with parent data when apartmentData changes
    useEffect(() => {
        if (apartmentData.imageUrl) setSelectedImage(apartmentData.imageUrl);
        if (apartmentData.description) setDescription(apartmentData.description);
        if (apartmentData.types) setSelectedTypes(apartmentData.types);
    }, [apartmentData]);

    // Notify parent when data changes (with debounce to avoid too many updates)
    useEffect(() => {
        const timeoutId = setTimeout(() => {
            const data = {
                imageUrl: selectedImage === '/download.png' ? '' : selectedImage,
                description: description.trim(),
                types: selectedTypes
            };
            
            // Preserve the apartment ID if it exists (for existing apartments)
            if (apartmentData.id) {
                data.id = apartmentData.id;
            }
            
            if (onDataChange) {
                onDataChange(data);
            }
        }, 300); // 300ms debounce

        return () => clearTimeout(timeoutId);
    }, [selectedImage, description, selectedTypes, apartmentData.id, onDataChange]);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            // Cleanup any remaining preview URLs
            if (selectedImage && selectedImage.startsWith('blob:')) {
                cleanupPreview(selectedImage);
            }
        };
    }, []);

    const handleTypeToggle = (type) => {
        if (disabled) return;
        
        setSelectedTypes(prev => {
            if (prev.includes(type)) {
                return prev.filter(t => t !== type);
            } else {
                return [...prev, type];
            }
        });
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
                    handleTypeToggle(result.data.name);
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


    const handleDelete = () => {
        if (window.confirm('Are you sure you want to delete this apartment?')) {
            if (onDelete) {
                onDelete(index);
            }
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
            gap: '16px',
            position: 'relative'
        }}>
            {/* Delete Button */}
            {onDelete && (
                <button
                    onClick={handleDelete}
                    style={{
                        position: 'absolute',
                        top: '10px',
                        right: '10px',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '50%',
                        width: '28px',
                        height: '28px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: 'pointer',
                        fontSize: '14px',
                        fontWeight: 'bold',
                        transition: 'background-color 0.2s ease',
                        zIndex: 10
                    }}
                    onMouseEnter={(e) => {
                        e.target.style.backgroundColor = '#dc2626';
                    }}
                    onMouseLeave={(e) => {
                        e.target.style.backgroundColor = '#ef4444';
                    }}
                    title="Delete Apartment"
                >
                    ×
                </button>
            )}
            
            {/* Image Section */}
            <div
                onClick={handleImageClick}
                onMouseEnter={() => setIsHovered(true)}
                onMouseLeave={() => setIsHovered(false)}
                                    style={{
                        width: '100%',
                        height: '200px',
                        cursor: disabled ? 'not-allowed' : 'pointer',
                        borderRadius: '8px',
                        overflow: 'hidden',
                        border: disabled ? '2px dashed #e5e7eb' : '2px dashed #d1d5db',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        position: 'relative',
                        opacity: disabled ? 0.6 : 1
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

            {/* Description Input */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <label style={{
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                }}>
                    Description :
                </label>
                <input
                    type="text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    disabled={disabled}
                    placeholder={disabled ? "Select a region first" : "Enter apartment description"}
                    style={{
                        padding: '10px 12px',
                        border: '1px solid #d1d5db',
                        borderRadius: '6px',
                        fontSize: '14px',
                        backgroundColor: disabled ? '#f3f4f6' : '#f9fafb',
                        outline: 'none',
                        cursor: disabled ? 'not-allowed' : 'text',
                        opacity: disabled ? 0.6 : 1
                    }}
                />
            </div>

            {/* Type Select */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <label style={{
                    fontSize: '14px',
                    fontWeight: '600',
                    color: '#374151'
                }}>
                    Type :
                </label>

                {!isAddingOption ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        {/* Type checkboxes */}
                        <div style={{ 
                            display: 'flex', 
                            flexWrap: 'wrap', 
                            gap: '12px',
                            minHeight: '40px',
                            padding: '12px',
                            border: '1px solid #e5e7eb',
                            borderRadius: '8px',
                            backgroundColor: disabled ? '#f3f4f6' : '#fafbfc'
                        }}>
                            {apartmentTypes.map((type, index) => {
                                const isSelected = selectedTypes.includes(type.name);
                                // Define colors for different apartment types
                                const getTypeColors = (typeName, selected) => {
                                    const colors = {
                                        'F1': { bg: '#10b981', hover: '#059669', light: '#d1fae5' },
                                        'F2': { bg: '#3b82f6', hover: '#2563eb', light: '#dbeafe' },
                                        'F3': { bg: '#8b5cf6', hover: '#7c3aed', light: '#ede9fe' },
                                        'F4': { bg: '#f59e0b', hover: '#d97706', light: '#fef3c7' },
                                        'F5': { bg: '#ef4444', hover: '#dc2626', light: '#fecaca' },
                                        'Studio': { bg: '#06b6d4', hover: '#0891b2', light: '#cffafe' }
                                    };
                                    
                                    const typeColor = colors[typeName] || colors['F1'];
                                    return {
                                        backgroundColor: selected ? typeColor.bg : typeColor.light,
                                        color: selected ? 'white' : typeColor.bg,
                                        borderColor: typeColor.bg,
                                        hoverBg: selected ? typeColor.hover : typeColor.bg
                                    };
                                };
                                
                                const colors = getTypeColors(type.name, isSelected);
                                
                                return (
                                    <label 
                                        key={type.id} 
                                        style={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '6px',
                                            padding: '8px 16px',
                                            backgroundColor: colors.backgroundColor,
                                            color: colors.color,
                                            border: `2px solid ${colors.borderColor}`,
                                            borderRadius: '8px',
                                            fontSize: '13px',
                                            fontWeight: '600',
                                            cursor: disabled ? 'not-allowed' : 'pointer',
                                            userSelect: 'none',
                                            opacity: disabled ? 0.6 : 1,
                                            transition: 'all 0.2s ease-in-out',
                                            minWidth: '60px',
                                            position: 'relative',
                                            transform: isSelected ? 'scale(1.05)' : 'scale(1)',
                                            boxShadow: isSelected ? '0 4px 12px rgba(0, 0, 0, 0.15)' : '0 2px 4px rgba(0, 0, 0, 0.05)'
                                        }}
                                        onMouseEnter={(e) => {
                                            if (!disabled) {
                                                e.target.style.backgroundColor = colors.hoverBg;
                                                e.target.style.color = 'white';
                                                e.target.style.transform = 'scale(1.08)';
                                                e.target.style.boxShadow = '0 6px 16px rgba(0, 0, 0, 0.2)';
                                            }
                                        }}
                                        onMouseLeave={(e) => {
                                            if (!disabled) {
                                                e.target.style.backgroundColor = colors.backgroundColor;
                                                e.target.style.color = colors.color;
                                                e.target.style.transform = isSelected ? 'scale(1.05)' : 'scale(1)';
                                                e.target.style.boxShadow = isSelected ? '0 4px 12px rgba(0, 0, 0, 0.15)' : '0 2px 4px rgba(0, 0, 0, 0.05)';
                                            }
                                        }}
                                    >
                                        <input
                                            type="checkbox"
                                            checked={isSelected}
                                            onChange={() => handleTypeToggle(type.name)}
                                            disabled={disabled}
                                            style={{ display: 'none' }}
                                        />
                                        {isSelected && (
                                            <svg 
                                                width="16" 
                                                height="16" 
                                                viewBox="0 0 24 24" 
                                                fill="none" 
                                                style={{ marginRight: '2px' }}
                                            >
                                                <path 
                                                    d="M20 6L9 17L4 12" 
                                                    stroke="currentColor" 
                                                    strokeWidth="2" 
                                                    strokeLinecap="round" 
                                                    strokeLinejoin="round"
                                                />
                                            </svg>
                                        )}
                                        {type.name}
                                    </label>
                                );
                            })}
                            {selectedTypes.length === 0 && (
                                <span style={{ color: '#9ca3af', fontSize: '12px', fontStyle: 'italic' }}>
                                    {disabled ? 'Select a region first' : 'Select apartment types'}
                                </span>
                            )}
                        </div>
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
                                alignSelf: 'center',
                                marginTop: '15px'
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
                                <path d="M12 5v14M5 12h14" />
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
                            placeholder="Enter new type option"
                            style={{
                                padding: '10px 12px',
                                border: '1px solid #d1d5db',
                                borderRadius: '6px',
                                fontSize: '14px',
                                backgroundColor: '#f9fafb',
                                outline: 'none'
                            }}
                        />
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                            <button
                                onClick={handleAddOption}
                                style={{
                                    backgroundColor: 'white',
                                    border: '2px solid #d1d5db',
                                    borderRadius: '8px',
                                    padding: '6px 12px',
                                    fontSize: '12px',
                                    fontWeight: '600',
                                    color: '#374151',
                                    cursor: 'pointer'
                                }}
                            >
                                Add
                            </button>
                            <button
                                onClick={handleCancelAdd}
                                style={{
                                    backgroundColor: 'white',
                                    border: '2px solid #d1d5db',
                                    borderRadius: '8px',
                                    padding: '6px 12px',
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

        </div>
    );
};

export default BestSellerImageEditor;
