import React from 'react';

const TableStats = ({ title = "PENDING ORDERS", number = "12", subtitle = "orders completed", gradientColors = ["#3b82f6", "#60a5fa"] }) => {
    return (
        <div style={{
            borderRadius: '30px',
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
            width: '200px',
            height: '150px',
            boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)'
        }}>
            {/* First div with blue gradient and title */}
            <div style={{
                background: `linear-gradient(135deg, ${gradientColors[0]} 0%, ${gradientColors[1]} 100%)`,
                padding: '12px 20px',
                flex: '1',
                display: 'flex',
                alignItems: 'center'
            }}>
                <span style={{
                    color: 'white',
                    fontSize: '12px',
                    fontWeight: '600',
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px'
                }}>
                    {title}
                </span>
            </div>

            {/* Second div with number and subtitle */}
            <div style={{
                backgroundColor: 'white',
                padding: '20px',
                flex: '2',
                display: 'flex',
                alignItems: 'center',
                gap: '10px'
            }}>
                <span style={{
                    fontSize: '36px',
                    fontWeight: 'bold',
                    color: '#1f2937',
                    lineHeight: '1'
                }}>
                    {number}
                </span>
                <span style={{
                    fontSize: '14px',
                    color: '#9ca3af',
                    fontWeight: '400'
                }}>
                    {subtitle}
                </span>
            </div>
        </div>
    );
};

export default TableStats;
