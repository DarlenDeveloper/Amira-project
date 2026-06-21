import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { useCollection, usePaginatedCollection } from '../db.js';
import { money } from '../utils.js';

export default function Overview() {
  const { data: orders } = useCollection('orders');
  const { data: users } = useCollection('users');
  const { data: products } = useCollection('products');
  const { data: appointments } = useCollection('appointments');
  const { data: conversations } = useCollection('conversations');
  const { data: renders } = usePaginatedCollection('renders', {
    orderByField: 'createdAt',
    orderDir: 'desc',
    pageSize: 100,
  });

  const revenue = useMemo(
    () => orders.reduce((s, o) => s + (o.total || 0), 0),
    [orders],
  );
  const openConvos = conversations.filter((c) => c.status === 'open').length;
  const pendingAppts = appointments.filter((a) => a.status === 'requested').length;
  const lowStock = products.filter((p) => p.status && p.status !== 'active').length;
  const renders7d = useMemo(() => {
    const cutoff = Date.now() - 7 * 24 * 60 * 60 * 1000;
    return renders.filter((r) => (r.createdAt?.toMillis?.() ?? 0) >= cutoff).length;
  }, [renders]);

  const stats = [
    { label: 'Revenue', value: money(revenue), foot: `${orders.length} orders` },
    { label: 'Customers', value: users.length, foot: 'Active accounts' },
    { label: 'Renders (7d)', value: renders7d, foot: `${renders.length} loaded` },
    { label: 'Open chats', value: openConvos, foot: `${conversations.length} total` },
  ];

  const recent = useMemo(() => {
    return [...orders]
      .sort((a, b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))
      .slice(0, 5);
  }, [orders]);

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
                    <td className="mono">{o.orderId}</td>
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
            <Link to="/renders" className="attention-item">
              <span className="attention-num serif-num">{renders7d}</span>
              <span className="attention-text">Visual Studio renders this week</span>
            </Link>
            <Link to="/products" className="attention-item">
              <span className="attention-num serif-num">{lowStock}</span>
              <span className="attention-text">Products low or out of stock</span>
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
