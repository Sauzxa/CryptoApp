import React, { useState, useEffect } from 'react';
import { getHeroSectionNumbers, updateHeroSectionNumbers } from '../utils/api';

const HeroStatEditor = ({ title, placeholder = '', fieldKey }) => {
  const [value, setValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [heroData, setHeroData] = useState(null);
  const [isEditing, setIsEditing] = useState(false);

  // Load hero section numbers on component mount
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await getHeroSectionNumbers();
        if (response.success && response.data) {
          setHeroData(response.data);
          // Set the initial value based on the fieldKey
          switch(fieldKey) {
            case 'propertiesListed':
              setValue(response.data.propertiesListed || '');
              break;
            case 'happyClients':
              setValue(response.data.happyClients || '');
              break;
            case 'daysToClose':
              setValue(response.data.daysToClose || '');
              break;
            default:
              setValue('');
          }
        }
      } catch (error) {
        console.error('Error fetching hero section numbers:', error);
      }
    };
    
    fetchData();
  }, [fieldKey]);

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    setIsEditing(false);
    // Reset value to original data
    if (heroData) {
      switch(fieldKey) {
        case 'propertiesListed':
          setValue(heroData.propertiesListed || '');
          break;
        case 'happyClients':
          setValue(heroData.happyClients || '');
          break;
        case 'daysToClose':
          setValue(heroData.daysToClose || '');
          break;
        default:
          setValue('');
      }
    }
  };

  const handleSave = async () => {
    if (!heroData || !value.trim()) return;

    setIsLoading(true);
    try {
      const updatedData = {
        ...heroData,
        [fieldKey]: value.trim()
      };

      const response = await updateHeroSectionNumbers(updatedData);
      if (response.success) {
        setHeroData(response.data);
        setIsEditing(false);
        alert('Hero section number updated successfully!');
      } else {
        alert('Failed to update: ' + response.error);
      }
    } catch (error) {
      console.error('Error updating hero section numbers:', error);
      alert('Error updating hero section number');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <style>
        {`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}
      </style>
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
        {/* Title */}
      <div style={{ textAlign: 'left' }}>
        <h3 style={{
          margin: 0,
          fontSize: '16px',
          fontWeight: 600,
          color: '#111827'
        }}>
          {title}
        </h3>
      </div>

      {/* Input (disabled by default, enabled only when editing) */}
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        disabled={!isEditing || isLoading}
        style={{
          padding: '12px',
          border: '1px solid #d1d5db',
          borderRadius: '10px',
          fontSize: '14px',
          backgroundColor: !isEditing || isLoading ? '#f3f4f6' : '#ffffff',
          color: !isEditing ? '#6b7280' : '#111827',
          outline: 'none',
          opacity: isLoading ? 0.7 : 1,
          cursor: !isEditing ? 'not-allowed' : 'text'
        }}
      />

      {/* Action Buttons */}
      {!isEditing ? (
        /* Edit Button - Show when not editing */
        <button
          onClick={handleEdit}
          disabled={isLoading}
          style={{
            padding: '10px 16px',
            backgroundColor: isLoading ? '#9ca3af' : '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '600',
            cursor: isLoading ? 'not-allowed' : 'pointer',
            transition: 'background-color 0.2s ease',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px'
          }}
          onMouseEnter={(e) => {
            if (!isLoading) {
              e.target.style.backgroundColor = '#2563eb';
            }
          }}
          onMouseLeave={(e) => {
            if (!isLoading) {
              e.target.style.backgroundColor = '#3b82f6';
            }
          }}
        >
          ✏️ Edit
        </button>
      ) : (
        /* Save and Cancel Buttons - Show when editing */
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={handleCancel}
            disabled={isLoading}
            style={{
              flex: 1,
              padding: '10px 16px',
              backgroundColor: isLoading ? '#9ca3af' : '#6b7280',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '14px',
              fontWeight: '600',
              cursor: isLoading ? 'not-allowed' : 'pointer',
              transition: 'background-color 0.2s ease',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}
            onMouseEnter={(e) => {
              if (!isLoading) {
                e.target.style.backgroundColor = '#4b5563';
              }
            }}
            onMouseLeave={(e) => {
              if (!isLoading) {
                e.target.style.backgroundColor = '#6b7280';
              }
            }}
          >
            ❌ Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={isLoading || !value.trim()}
            style={{
              flex: 1,
              padding: '10px 16px',
              backgroundColor: isLoading || !value.trim() ? '#9ca3af' : '#10b981',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              fontSize: '14px',
              fontWeight: '600',
              cursor: isLoading || !value.trim() ? 'not-allowed' : 'pointer',
              transition: 'background-color 0.2s ease',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}
            onMouseEnter={(e) => {
              if (!isLoading && value.trim()) {
                e.target.style.backgroundColor = '#059669';
              }
            }}
            onMouseLeave={(e) => {
              if (!isLoading && value.trim()) {
                e.target.style.backgroundColor = '#10b981';
              }
            }}
          >
            {isLoading ? (
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
              '💾 Save'
            )}
          </button>
        </div>
      )}
      </div>
    </>
  );
};

export default HeroStatEditor;
