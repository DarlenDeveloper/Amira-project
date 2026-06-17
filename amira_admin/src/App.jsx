import { Routes, Route } from 'react-router-dom';
import { useAuth } from './auth.jsx';
import Sidebar from './components/Sidebar.jsx';
import Login from './pages/Login.jsx';
import Overview from './pages/Overview.jsx';
import Products from './pages/Products.jsx';
import Portfolio from './pages/Portfolio.jsx';
import Orders from './pages/Orders.jsx';
import Customers from './pages/Customers.jsx';
import Conversations from './pages/Conversations.jsx';
import Appointments from './pages/Appointments.jsx';
import Notifications from './pages/Notifications.jsx';

export default function App() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="auth-loading">
        <span className="login-name">AMIRA</span>
      </div>
    );
  }

  if (!user) return <Login />;

  return (
    <div className="admin-shell">
      <Sidebar />
      <main className="admin-main">
        <Routes>
          <Route path="/" element={<Overview />} />
          <Route path="/products" element={<Products />} />
          <Route path="/portfolio" element={<Portfolio />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/customers" element={<Customers />} />
          <Route path="/conversations" element={<Conversations />} />
          <Route path="/appointments" element={<Appointments />} />
          <Route path="/notifications" element={<Notifications />} />
        </Routes>
      </main>
    </div>
  );
}
