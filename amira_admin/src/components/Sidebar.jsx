import { NavLink } from 'react-router-dom';
import { useAuth } from '../auth.jsx';
import {
  OverviewIcon, ProductsIcon, OrdersIcon, CustomersIcon,
  ChatIcon, CalendarIcon, BellIcon, AnalyticsIcon, SettingsIcon, PortfolioIcon, AgentIcon,
} from './icons.jsx';

const manage = [
  { to: '/', label: 'Overview', Icon: OverviewIcon, end: true },
  { to: '/products', label: 'Products', Icon: ProductsIcon },
  { to: '/portfolio', label: 'Portfolio', Icon: PortfolioIcon },
  { to: '/orders', label: 'Orders', Icon: OrdersIcon },
  { to: '/customers', label: 'Customers', Icon: CustomersIcon },
  { to: '/conversations', label: 'Conversations', Icon: ChatIcon },
  { to: '/renders', label: 'Visual Studio', Icon: PortfolioIcon },
  { to: '/appointments', label: 'Appointments', Icon: CalendarIcon },
  { to: '/notifications', label: 'Notifications', Icon: BellIcon },
  { to: '/agent', label: 'AI Agent', Icon: AgentIcon },
  { to: '/analytics', label: 'Analytics', Icon: AnalyticsIcon },
];

const comingSoon = [
  { label: 'Settings', Icon: SettingsIcon },
];

export default function Sidebar() {
  const { user, logout } = useAuth();
  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-name">AMIRA</span>
        <span className="brand-sub">ATELIER · ADMIN</span>
      </div>

      <nav className="nav">
        <p className="nav-group">Manage</p>
        {manage.map(({ to, label, Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) => `nav-item${isActive ? ' nav-item--active' : ''}`}
          >
            <Icon className="nav-icon" />
            <span>{label}</span>
          </NavLink>
        ))}

        <p className="nav-group nav-group--spaced">Coming soon</p>
        {comingSoon.map(({ label, Icon }) => (
          <span key={label} className="nav-item nav-item--disabled">
            <Icon className="nav-icon" />
            <span>{label}</span>
          </span>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-user">
          <span className="sidebar-user-label">Signed in as</span>
          <span className="sidebar-user-email">{user?.email}</span>
        </div>
        <button type="button" className="logout-btn" onClick={logout}>
          Sign out
        </button>
      </div>
    </aside>
  );
}
