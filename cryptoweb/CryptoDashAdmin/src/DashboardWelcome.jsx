import React from 'react';

const DashboardWelcome = ({ username = "USER" }) => {
    return (
        <div style={{
            background: 'linear-gradient(135deg,rgb(185, 187, 192) 0%, #9ca3af 100%)',
            borderRadius: '12px',
            padding: '20px 20px',
            margin: '20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '80px'
        }}>
            <h1 style={{
                fontSize: '28px',
                fontWeight: '600',
                color: 'black',
                textAlign: 'left',
                margin: 0,
                letterSpacing: '1px',
                textTransform: 'uppercase',
                fontFamily: 'Poppins, sans-serif'
            }}>
                Welcome to your dashboard experience {username}
            </h1>
        </div>
    );
};

export default DashboardWelcome;
