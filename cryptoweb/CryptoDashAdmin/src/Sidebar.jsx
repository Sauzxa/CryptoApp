import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from './contexts/AuthContext';
import DashboardTitle from './DashboardTitle';
import DashboardElement from './DashboardElement';

// Import icons
import Icon1 from './assets/icons/Icons-1.png';
import Icon2 from './assets/icons/Icons-2.png';
import Icon3 from './assets/icons/Icons-3.png';
import Icon4 from './assets/icons/Icons-4.png';
import SmallLogo from './assets/small logo.png';

const Sidebar = () => {
    const [isExpanded, setIsExpanded] = useState(true);
    const navigate = useNavigate();
    const { logout } = useAuth();

    const toggleSidebar = () => {
        setIsExpanded(!isExpanded);
    };

    const handleNavigation = (path) => {
        navigate(path);
    };

    const handleLogout = () => {
        logout();
    };

    return (
        <div
            style={{
                width: isExpanded ? '250px' : '60px',
                height: '100vh',
                backgroundColor: 'white',
                borderRight: '1px solid #e0e0e0',
                display: 'flex',
                flexDirection: 'column',
                transition: 'width 0.3s ease',
                position: 'relative'
            }}
        >
            {/* Dashboard Title at top - expanded */}
            <div style={{
                padding: '30px',
                display: isExpanded ? 'block' : 'none'
            }}>
                <DashboardTitle />
            </div>

            {/* Logo only - collapsed */}
            <div style={{
                padding: '20px',
                display: !isExpanded ? 'flex' : 'none',
                justifyContent: 'center',
                alignItems: 'center'
            }}>
                <img
                    src={SmallLogo}
                    alt="Logo"
                    style={{
                        width: '30px',
                        height: '30px'
                    }}
                />
            </div>

            {/* Dashboard Elements */}
            <div style={{
                padding: '0 30px',
                display: isExpanded ? 'flex' : 'none',
                flexDirection: 'column',
                gap: '8px'
            }}>

                <div onClick={() => handleNavigation('/orders')}>
                    <DashboardElement
                        icon={Icon1}
                        text="Orders"
                    />
                </div>
                <div onClick={() => handleNavigation('/landing-page-content')}>
                    <DashboardElement
                        icon={Icon2}
                        text="Landing Page Content"
                    />
                </div>
                <div onClick={() => handleNavigation('/apartment-types')}>
                    <DashboardElement
                        icon={Icon3}
                        text="Apartment Types"
                    />
                </div>
            </div>

            {/* Empty content area */}
            <div style={{ flex: 1 }}></div>

            {/* Logout button */}
            <div style={{
                padding: '0 30px 0 30px',
                marginBottom: '80px',
                display: isExpanded ? 'block' : 'none'
            }}>
                <div onClick={handleLogout}>
                    <DashboardElement
                        icon={Icon4}
                        text="Logout"
                    />
                </div>
            </div>

            {/* Toggle button at bottom */}
            <button
                onClick={toggleSidebar}
                style={{
                    position: 'absolute',
                    bottom: '20px',
                    left: '50%',
                    transform: 'translateX(-50%)',
                    width: '40px',
                    height: '40px',
                    backgroundColor: '#f5f5f5',
                    border: '1px solid #ddd',
                    borderRadius: '50%',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '16px',
                    color: '#666',
                    transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                    e.target.style.backgroundColor = '#e8e8e8';
                }}
                onMouseLeave={(e) => {
                    e.target.style.backgroundColor = '#f5f5f5';
                }}
            >
                {isExpanded ? '←' : '→'}
            </button>
        </div>
    );
};

export default Sidebar;