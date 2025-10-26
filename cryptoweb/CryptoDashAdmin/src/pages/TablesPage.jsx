import React, { useEffect } from 'react';
import { useData } from '../hooks/useData';
import DashboardWelcome from '../DashboardWelcome';
import TableStats from '../TableStats';
import DataTable from '../DataTable';

const TablesPage = () => {
  const { 
    reservationStats, 
    loading, 
    fetchReservationStats 
  } = useData();

  // Load reservation stats on component mount
  useEffect(() => {
    fetchReservationStats();
  }, [fetchReservationStats]);

  return (
    <>
      <DashboardWelcome username="CRYPTO USER" />
      
      {/* Stats Section */}
      <section style={{
        display: 'flex',
        gap: '20px',
        padding: '20px',
        justifyContent: 'center',
        width: '100%'
      }}>
        <TableStats 
          title="PENDING RESERVATIONS" 
          number={loading.stats ? "..." : reservationStats.pending.toString()} 
          subtitle="pending reservations"
          gradientColors={["#f59e0b", "#fbbf24"]}
        />
        <TableStats 
          title="COMPLETED RESERVATIONS" 
          number={loading.stats ? "..." : reservationStats.completed.toString()} 
          subtitle="completed successfully"
          gradientColors={["#10b981", "#34d399"]}
        />
        <TableStats 
          title="TOTAL RESERVATIONS" 
          number={loading.stats ? "..." : reservationStats.total.toString()} 
          subtitle="total bookings"
          gradientColors={["#3b82f6", "#60a5fa"]}
        />
      </section>
      
      {/* Data Table Section */}
      <DataTable />
    </>
  );
};

export default TablesPage;
