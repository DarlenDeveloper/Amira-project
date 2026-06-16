import { Link } from 'react-router-dom';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { orders } from '../data/orders.js';
import { customers } from '../data/customers.js';
import { products } from '../data/products.js';
import { appointments } from '../data/appointments.js';
import { conversations } from '../data/conversations.js';
import { money } from '../utils.js';

export default function Overview() {
  const revenue = orders.reduce((s, o) => s + o.total, 0);
  const openConvos = conversations.filter((c) => c.status === 'open').length;
  const pendingAppts = appointments.filter((a) => a.status === 'requested').length;

  const stats = [
    { label: 'Revenue', value: money(revenue), foot: `${orders.length} orders` },
    { label: 'Customers', value: customers.length, foot: 'Active accounts' },
    { label: 'Products', value: products.length, foot: 'In catalogue' },
    { label: 'Open chats', value: openConvos, foot: `${conversations.length} total` },
  ];

  const recent = orders.slice(0, 5);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Dashboard"
        title="Overview"
        subtitle="A snapshot of the Amira atelier today."
      />

      <div className="stat-grid">
        {stats.map((s) => (
          <div className="stat-card" key={s.label}>
            <span className="stat-label">{s.label}</span>
            <span className="stat-value serif-num">{s.value}</span>
            <span className="stat-foot">{s.foot}</span>
          </div>
        ))}
      </div>

      <div className="overview-cols">
        {/* Recent orders */}
        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Recent orders</h2>
            <Link className="panel-link" to="/orders">View all</Link>
          </div>
          <div className="table-card table-card--flush">
            <table className="data-table">
              <tbody>
                {recent.map((o) => (
                  <tr key={o.id}>
                    <td className="mono">{o.id}</td>
                    <td className="cell-strong">{o.customer}</td>
                    <td><StatusBadge status={o.status} /></td>
                    <td className="num serif-num">{money(o.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* Needs attention */}
        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Needs attention</h2>
          </div>
          <div className="attention-list">
            <Link to="/conversations" className="attention-item">
              <span className="attention-num serif-num">{openConvos}</span>
              <span className="attention-text">Open conversations awaiting a reply</span>
            </Link>
            <Link to="/appointments" className="attention-item">
              <span className="attention-num serif-num">{pendingAppts}</span>
              <span className="attention-text">Appointment requests to confirm</span>
            </Link>
            <Link to="/products" className="attention-item">
              <span className="attention-num serif-num">
                {products.filter((p) => p.status !== 'active').length}
              </span>
              <span className="attention-text">Products low or out of stock</span>
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
