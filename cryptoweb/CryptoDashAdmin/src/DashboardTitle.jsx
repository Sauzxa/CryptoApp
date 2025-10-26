import React from 'react';
import smallLogo from './assets/small logo.png';

const DashboardTitle = () => {
    return (
        <div style={{
            display: 'flex',
            flexDirection: 'row',
            alignItems: 'center',
            gap: '12px'
        }}>
            <img
                src={smallLogo}
                alt="Logo"
                style={{
                    width: '40px',
                    height: '40px'
                }}
            />
            <div style={{
                display: 'flex',
                flexDirection: 'column'
            }}>
                <div style={{
                    fontWeight: 'bold',
                    color: 'black',
                    fontSize: '16px'
                }}>
                    Crypto Dashboard
                </div>
                <div style={{
                    color: '#888',
                    fontSize: '10px',
                    wordBreak: 'break-all',
                    lineHeight: '1.2',
                    maxWidth: '160px',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap'
                }}>
                    crypto.immobilier@gmail.com
                </div>
            </div>
        </div>
    );
};

export default DashboardTitle;
