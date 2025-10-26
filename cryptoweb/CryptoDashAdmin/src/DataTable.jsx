import React, { useState, useEffect } from 'react';
import { useData } from './hooks/useData';

const DataTable = () => {
    const { 
        reservations, 
        loading, 
        error, 
        fetchReservations, 
        updateReservation,
        deleteReservationData,
        clearError 
    } = useData();

    // Add CSS animations and dropdown styling for professional effects
    useEffect(() => {
        const style = document.createElement('style');
        style.textContent = `
            @keyframes spin {
                from { transform: rotate(0deg); }
                to { transform: rotate(360deg); }
            }
            @keyframes pulse {
                0%, 100% { opacity: 1; transform: scale(1); }
                50% { opacity: 0.7; transform: scale(0.9); }
            }
            @keyframes shimmer {
                0% { background-position: 200% 0; }
                100% { background-position: -200% 0; }
            }
            @keyframes slideDown {
                from {
                    opacity: 0;
                    transform: translateY(-10px) scale(0.95);
                }
                to {
                    opacity: 1;
                    transform: translateY(0) scale(1);
                }
            }

        `;
        document.head.appendChild(style);
        
        return () => {
            document.head.removeChild(style);
        };
    }, []);

    const [updatingStatus, setUpdatingStatus] = useState(null);
    const [deletingOrder, setDeletingOrder] = useState(null);
    const [openDropdowns, setOpenDropdowns] = useState({});

    // Load reservations on component mount
    useEffect(() => {
        fetchReservations();
    }, [fetchReservations]);

    // Close dropdowns when clicking outside
    useEffect(() => {
        const handleClickOutside = () => {
            setOpenDropdowns({});
        };

        document.addEventListener('click', handleClickOutside);
        return () => document.removeEventListener('click', handleClickOutside);
    }, []);

    const statusOptions = [
        { 
            value: 'Pending', 
            label: 'Pending', 
            color: '#FB8C00', 
            bgColor: '#FFF3E0',
            hoverBgColor: '#FFE0B2'
        },
        { 
            value: 'Done', 
            label: 'Done', 
            color: '#43A047', 
            bgColor: '#E8F5E9',
            hoverBgColor: '#C8E6C9'
        }
    ];

    const getStatusColor = (status) => {
        const option = statusOptions.find(opt => opt.value === status);
        return option ? option.color : '#6b7280';
    };

    const handleStatusChange = async (reservationId, newStatus) => {
        setUpdatingStatus(reservationId);
        setOpenDropdowns({}); // Close all dropdowns
        
        try {
            const result = await updateReservation(reservationId, newStatus);
            if (!result.success) {
                // Show error message (you could use a toast notification here)
                console.error('Failed to update status:', result.error);
            }
        } catch (error) {
            console.error('Error updating status:', error);
        } finally {
            setUpdatingStatus(null);
        }
    };
    
    const handleDelete = async (reservationId) => {
        if (!confirm('Are you sure you want to delete this order?')) {
            return;
        }
        
        setDeletingOrder(reservationId);
        
        try {
            const result = await deleteReservationData(reservationId);
            if (!result.success) {
                console.error('Failed to delete reservation:', result.error);
            }
        } catch (error) {
            console.error('Error deleting reservation:', error);
        } finally {
            setDeletingOrder(null);
        }
    };

    const toggleDropdown = (reservationId) => {
        setOpenDropdowns(prev => ({
            ...prev,
            [reservationId]: !prev[reservationId]
        }));
    };

    const closeDropdown = (reservationId) => {
        setOpenDropdowns(prev => ({
            ...prev,
            [reservationId]: false
        }));
    };

    // Format date for display
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    };

    const TableHeader = ({ icon, title }) => (
        <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '16px 20px',
            flex: 1,
            fontSize: '14px',
            fontWeight: '500',
            color: '#374151'
        }}>
            <img
                src={icon}
                alt={title}
                style={{
                    width: '16px',
                    height: '16px',
                    opacity: 0.7
                }}
            />
            <span>{title}</span>
        </div>
    );

    // Show loading state
    if (loading.reservations) {
        return (
            <div style={{
                backgroundColor: 'white',
                borderRadius: '30px',
                padding: '40px',
                margin: '20px',
                maxWidth: '1200px',
                marginLeft: 'auto',
                marginRight: 'auto',
                textAlign: 'center'
            }}>
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '12px',
                    color: '#6b7280'
                }}>
                    <div style={{
                        width: '20px',
                        height: '20px',
                        border: '2px solid #e5e7eb',
                        borderTop: '2px solid #3b82f6',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }} />
                    Loading reservations...
                </div>
            </div>
        );
    }

    // Show error state
    if (error) {
        return (
            <div style={{
                backgroundColor: 'white',
                borderRadius: '30px',
                padding: '40px',
                margin: '20px',
                maxWidth: '1200px',
                marginLeft: 'auto',
                marginRight: 'auto',
                textAlign: 'center'
            }}>
                <div style={{
                    color: '#ef4444',
                    marginBottom: '16px'
                }}>
                    Error loading reservations: {error}
                </div>
                <button
                    onClick={() => {
                        clearError();
                        fetchReservations();
                    }}
                    style={{
                        backgroundColor: '#3b82f6',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '8px 16px',
                        cursor: 'pointer'
                    }}
                >
                    Retry
                </button>
            </div>
        );
    }

    return (
        <div style={{
            backgroundColor: 'white',
            borderRadius: '30px',
            overflow: 'visible',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            margin: '20px',
            maxWidth: '1200px',
            marginLeft: 'auto',
            marginRight: 'auto',
            position: 'relative'
        }}>
            {/* Table Header */}
            <div style={{
                display: 'flex',
                backgroundColor: '#e5e7eb',
                borderBottom: '1px solid #d1d5db'
            }}>
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' /%3E%3C/svg%3E"
                    title="name"
                />
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z' /%3E%3C/svg%3E"
                    title="Number"
                />
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' /%3E%3C/svg%3E"
                    title="Apartment Type"
                />
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z' /%3E%3C/svg%3E"
                    title="Message"
                />
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' /%3E%3C/svg%3E"
                    title="Date"
                />
                <TableHeader
                    icon="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='currentColor'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' /%3E%3C/svg%3E"
                    title="Status"
                />
            </div>

            {/* Table Body */}
            <div style={{ overflow: 'visible' }}>
                {reservations.length === 0 ? (
                    <div style={{
                        padding: '40px',
                        textAlign: 'center',
                        color: '#6b7280'
                    }}>
                        No reservations found
                    </div>
                ) : (
                    reservations.map((reservation, index) => (
                        <div
                            key={reservation.id}
                            style={{
                                display: 'flex',
                                borderBottom: index < reservations.length - 1 ? '1px solid #f3f4f6' : 'none',
                                backgroundColor: 'white'
                            }}
                        >
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                color: '#374151'
                            }}>
                                {reservation.name}
                            </div>
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                color: '#374151'
                            }}>
                                {reservation.number}
                            </div>
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                color: '#374151'
                            }}>
                                {reservation.typeAppartement || 'N/A'}
                            </div>
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                color: '#374151',
                                maxWidth: '200px',
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap'
                            }} title={reservation.message}>
                                {reservation.message || 'No message'}
                            </div>
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                color: '#374151'
                            }}>
                                {formatDate(reservation.reservationDate)}
                            </div>
                            <div style={{
                                padding: '16px 20px',
                                flex: 1,
                                fontSize: '14px',
                                position: 'relative',
                                zIndex: openDropdowns[reservation.id] ? 10 : 1,
                                display: 'flex',
                                alignItems: 'center',
                                gap: '10px'
                            }}>
                                <div style={{
                                    position: 'relative',
                                    display: 'inline-block',
                                    minWidth: '120px'
                                }}>
                                    {/* Custom Dropdown Button */}
                                    <div 
                                        style={{
                                            position: 'relative',
                                            display: 'flex',
                                            alignItems: 'center',
                                            background: updatingStatus === reservation.id 
                                                ? 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)'
                                                : `linear-gradient(135deg, ${getStatusColor(reservation.status)}15 0%, ${getStatusColor(reservation.status)}08 100%)`,
                                            borderRadius: '12px',
                                            padding: '10px 16px',
                                            border: `2px solid ${getStatusColor(reservation.status)}25`,
                                            boxShadow: updatingStatus === reservation.id 
                                                ? '0 2px 8px rgba(0, 0, 0, 0.1)'
                                                : `0 4px 12px ${getStatusColor(reservation.status)}20, 0 2px 4px rgba(0, 0, 0, 0.1)`,
                                            opacity: updatingStatus === reservation.id ? 0.7 : 1,
                                            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                            cursor: updatingStatus === reservation.id ? 'not-allowed' : 'pointer',
                                            userSelect: 'none'
                                        }}
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            if (updatingStatus !== reservation.id) {
                                                toggleDropdown(reservation.id);
                                            }
                                        }}
                                        onMouseEnter={(e) => {
                                            if (updatingStatus !== reservation.id) {
                                                e.target.style.transform = 'translateY(-1px)';
                                                e.target.style.boxShadow = `0 6px 20px ${getStatusColor(reservation.status)}30, 0 4px 8px rgba(0, 0, 0, 0.15)`;
                                            }
                                        }}
                                        onMouseLeave={(e) => {
                                            if (updatingStatus !== reservation.id) {
                                                e.target.style.transform = 'translateY(0px)';
                                                e.target.style.boxShadow = `0 4px 12px ${getStatusColor(reservation.status)}20, 0 2px 4px rgba(0, 0, 0, 0.1)`;
                                            }
                                        }}
                                    >
                                        {/* Status Indicator Dot */}
                                        <div style={{
                                            width: '8px',
                                            height: '8px',
                                            borderRadius: '50%',
                                            backgroundColor: getStatusColor(reservation.status),
                                            marginRight: '10px',
                                            boxShadow: `0 0 8px ${getStatusColor(reservation.status)}60`,
                                            animation: updatingStatus === reservation.id 
                                                ? 'pulse 1.5s ease-in-out infinite' 
                                                : 'none'
                                        }} />
                                        
                                        {/* Loading Spinner */}
                                        {updatingStatus === reservation.id && (
                                            <div style={{
                                                width: '14px',
                                                height: '14px',
                                                border: '2px solid #e5e7eb',
                                                borderTop: '2px solid #3b82f6',
                                                borderRadius: '50%',
                                                animation: 'spin 1s linear infinite',
                                                marginRight: '10px'
                                            }} />
                                        )}
                                        
                                        {/* Status Text */}
                                        <span style={{
                                            color: getStatusColor(reservation.status),
                                            fontWeight: '600',
                                            fontSize: '14px',
                                            fontFamily: 'Inter, system-ui, sans-serif',
                                            flex: 1,
                                            textTransform: 'capitalize',
                                            letterSpacing: '0.025em'
                                        }}>
                                            {reservation.status}
                                        </span>
                                        
                                        {/* Dropdown Arrow */}
                                        <svg
                                            style={{
                                                width: '16px',
                                                height: '16px',
                                                fill: getStatusColor(reservation.status),
                                                transition: 'all 0.2s ease',
                                                opacity: updatingStatus === reservation.id ? 0.5 : 1,
                                                transform: openDropdowns[reservation.id] ? 'rotate(180deg)' : 'rotate(0deg)',
                                                background: 'transparent',
                                                marginLeft: '8px'
                                            }}
                                            viewBox="0 0 24 24"
                                        >
                                            <path d="M7 10l5 5 5-5z" />
                                        </svg>
                                    </div>

                                    {/* Custom Dropdown Menu */}
                                    {openDropdowns[reservation.id] && (
                                        <div style={{
                                            position: 'absolute',
                                            top: '100%',
                                            left: '0',
                                            right: '0',
                                            marginTop: '4px',
                                            backgroundColor: 'transparent',
                                            border: 'none',
                                            borderRadius: '12px',
                                            boxShadow: '0 10px 25px rgba(0, 0, 0, 0.15), 0 4px 6px rgba(0, 0, 0, 0.1)',
                                            zIndex: 9999,
                                            overflow: 'hidden',
                                            animation: 'slideDown 0.2s ease-out'
                                        }}
                                        onClick={(e) => e.stopPropagation()}
                                        >
                                            {statusOptions.map((option) => (
                                                <div
                                                    key={option.value}
                                                    style={{
                                                        padding: '14px 18px',
                                                        backgroundColor: option.bgColor,
                                                        color: option.color,
                                                        fontWeight: '600',
                                                        fontSize: '14px',
                                                        fontFamily: 'Inter, system-ui, sans-serif',
                                                        cursor: 'pointer',
                                                        borderBottom: option.value !== statusOptions[statusOptions.length - 1].value 
                                                            ? '1px solid rgba(0, 0, 0, 0.05)' 
                                                            : 'none',
                                                        textTransform: 'capitalize',
                                                        letterSpacing: '0.025em',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '10px',
                                                        borderRadius: option.value === statusOptions[0].value ? '12px 12px 0 0' : 
                                                                   option.value === statusOptions[statusOptions.length - 1].value ? '0 0 12px 12px' : '0'
                                                    }}
                                                    onClick={() => {
                                                        if (option.value !== reservation.status) {
                                                            handleStatusChange(reservation.id, option.value);
                                                        } else {
                                                            closeDropdown(reservation.id);
                                                        }
                                                    }}

                                                >
                                                    {/* Option Status Dot */}
                                                    <div style={{
                                                        width: '8px',
                                                        height: '8px',
                                                        borderRadius: '50%',
                                                        backgroundColor: option.color,
                                                        flexShrink: 0
                                                    }} />
                                                    
                                                    {/* Option Text */}
                                                    <span>{option.label}</span>
                                                    
                                                    {/* Current Selection Checkmark */}
                                                    {option.value === reservation.status && (
                                                        <svg
                                                            style={{
                                                                width: '16px',
                                                                height: '16px',
                                                                fill: option.color,
                                                                marginLeft: 'auto'
                                                            }}
                                                            viewBox="0 0 24 24"
                                                        >
                                                            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
                                                        </svg>
                                                    )}
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                                
                                {/* Delete Button */}
                                <button
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        handleDelete(reservation.id);
                                    }}
                                    disabled={deletingOrder === reservation.id}
                                    style={{
                                        background: deletingOrder === reservation.id 
                                            ? 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)'
                                            : 'linear-gradient(135deg, #fecaca 0%, #ef4444 100%)',
                                        borderRadius: '8px',
                                        padding: '8px 10px',
                                        border: '1px solid rgba(220, 38, 38, 0.3)',
                                        boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
                                        opacity: deletingOrder === reservation.id ? 0.7 : 1,
                                        transition: 'all 0.2s ease',
                                        cursor: deletingOrder === reservation.id ? 'not-allowed' : 'pointer',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        minWidth: '32px',
                                        height: '32px'
                                    }}
                                    onMouseEnter={(e) => {
                                        if (deletingOrder !== reservation.id) {
                                            e.target.style.transform = 'translateY(-1px)';
                                            e.target.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.15)';
                                        }
                                    }}
                                    onMouseLeave={(e) => {
                                        if (deletingOrder !== reservation.id) {
                                            e.target.style.transform = 'translateY(0)';
                                            e.target.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.1)';
                                        }
                                    }}
                                >
                                    {deletingOrder === reservation.id ? (
                                        <div style={{
                                            width: '14px',
                                            height: '14px',
                                            border: '2px solid rgba(255, 255, 255, 0.5)',
                                            borderTop: '2px solid white',
                                            borderRadius: '50%',
                                            animation: 'spin 1s linear infinite'
                                        }} />
                                    ) : (
                                        <svg 
                                            style={{
                                                width: '16px',
                                                height: '16px',
                                                fill: 'white'
                                            }}
                                            viewBox="0 0 24 24"
                                        >
                                            <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
                                        </svg>
                                    )}
                                </button>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
};

export default DataTable;


