import React, { useState } from 'react';

const DashboardElement = ({ icon, text = "Text Holder", onClick }) => {
    const [isHovered, setIsHovered] = useState(false);
    const [isClicked, setIsClicked] = useState(false);

    const handleClick = () => {
        setIsClicked(true);
        setTimeout(() => setIsClicked(false), 150);
        if (onClick) onClick();
    };

    return (
        <div
            style={{
                display: 'flex',
                flexDirection: 'row',
                alignItems: 'center',
                gap: '12px',
                borderRadius: '8px',
                padding: '12px 16px',
                cursor: 'pointer',
                backgroundColor: isClicked ? '#e0e0e0' : isHovered ? '#f5f5f5' : 'transparent',
                transition: 'background-color 0.2s ease',
                userSelect: 'none'
            }}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            onClick={handleClick}
        >
            <img 
                src={icon}
                alt="icon"
                style={{
                    width: '20px',
                    height: '20px',
                    objectFit: 'contain'
                }}
            />
            <div style={{
                fontSize: '14px',
                color: '#333',
                fontWeight: '400'
            }}>
                {text}
            </div>
        </div>
    );
};

export default DashboardElement;
