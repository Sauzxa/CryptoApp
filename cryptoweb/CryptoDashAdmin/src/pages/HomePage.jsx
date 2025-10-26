import React from 'react';

const HomePage = () => {
  return (
    <div style={{
      padding: '40px',
      textAlign: 'center',
      color: 'white'
    }}>
      <h1 style={{ fontSize: '3rem', marginBottom: '20px' }}>Welcome to Crypto Dashboard</h1>
      <p style={{ fontSize: '1.5rem', opacity: 0.8 }}>Select a section from the sidebar to get started</p>
    </div>
  );
};

export default HomePage;
