import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { DataProvider } from './contexts/DataContext';
import { ApartmentTypeProvider } from './contexts/ApartmentTypeContext';
import Sidebar from './Sidebar';
import HomePage from './pages/HomePage';
import TablesPage from './pages/TablesPage';
import ImagesPage from './pages/ImagesPage';
import HeroPage from './pages/HeroPage';
import ApartmentTypePage from './pages/ApartmentTypePage';
import LoginPage from './pages/LoginPage';
import backgroundImage from './assets/background.jpg';

// Protected route component
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  return children;
};

// Dashboard layout component for authenticated users
const DashboardLayout = ({ children }) => {
  return (
    <div style={{
      display: 'flex',
      height: '100vh',
      backgroundImage: `url(${backgroundImage})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      backgroundRepeat: 'no-repeat',
      margin: 0,
      padding: 0
    }}>
      <Sidebar />
      <div style={{
        flex: 1,
        backgroundColor: 'rgba(0, 0, 0, 0.3)',
        color: 'white',
        padding: '0',
        overflowY: 'auto',
        height: '100vh'
      }}>
        {children}
      </div>
    </div>
  );
};

// Main App content component that uses auth context
const AppContent = () => {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      {/* Login route - redirect to dashboard if already authenticated */}
      <Route 
        path="/login" 
        element={
          isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />
        } 
      />
      
      {/* Protected dashboard routes */}
      <Route 
        path="/" 
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <HomePage />
            </DashboardLayout>
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/orders" 
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <TablesPage />
            </DashboardLayout>
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/landing-page-content" 
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <ImagesPage />
            </DashboardLayout>
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/hero" 
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <HeroPage />
            </DashboardLayout>
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/apartment-types" 
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <ApartmentTypePage />
            </DashboardLayout>
          </ProtectedRoute>
        } 
      />
      
      {/* Backward compatibility routes - redirect old URLs to new ones */}
      <Route path="/tables" element={<Navigate to="/orders" replace />} />
      <Route path="/images" element={<Navigate to="/landing-page-content" replace />} />
      <Route path="/apartments" element={<Navigate to="/apartment-types" replace />} />
      
      {/* Catch all route - redirect to login */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
};

function App() {
  return (
    <AuthProvider>
      <DataProvider>
        <ApartmentTypeProvider>
          <Router>
            <AppContent />
          </Router>
        </ApartmentTypeProvider>
      </DataProvider>
    </AuthProvider>
  );
}

export default App;
