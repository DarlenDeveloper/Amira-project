import { useMemo } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { useCollection, formatDateTime } from '../db.js';
import { money } from '../utils.js';

const initials = (name) =>
  (name || '?')
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();

export default function Customers() {
  const { data: users } = useCollection('users');
  const { data: orders } = useCollection('orders');
  const { data: renders } = useCollection('renders');
  const { data: conversations } = useCollection('conversations');

  const customers = useMemo(() => {
    const byUid = {};
    for (const o of orders) {
      if (!o.uid) continue;
      const agg = byUid[o.uid] ?? { count: 0, spent: 0, renders: 0, lastChat: 0 };
      agg.count += 1;
      agg.spent += o.total || 0;
      byUid[o.uid] = agg;
    }
    for (const r of renders) {
      if (!r.uid) continue;
      const agg = byUid[r.uid] ?? { count: 0, spent: 0, renders: 0, lastChat: 0 };
      agg.renders += 1;
      byUid[r.uid] = agg;
    }
    for (const c of conversations) {
      if (!c.uid) continue;
      const agg = byUid[c.uid] ?? { count: 0, spent: 0, renders: 0, lastChat: 0 };
      const t = c.updatedAt?.toMillis?.() ?? 0;
      if (t > agg.lastChat) agg.lastChat = t;
      byUid[c.uid] = agg;
    }
    return users.map((u) => {
      const agg = byUid[u.id] ?? { count: 0, spent: 0, renders: 0, lastChat: 0 };
      return {
        id: u.id,
        name: u.name || u.email || u.phone || 'Amira Member',
        email: u.email || u.phone || '',
        phone: u.phone || '—',
        location: u.address || '—',
        orders: agg.count,
        spent: agg.spent,
        renders: agg.renders,
        lastChat: agg.lastChat
          ? formatDateTime(new Date(agg.lastChat))
          : '—',
        joined: formatDateTime(u.createdAt) || '—',
      };
    });
  }, [users, orders, renders, conversations]);

  const totalSpent = customers.reduce((s, c) => s + c.spent, 0);

  return (
    <div className="page">
      <PageHeader
        eyebrow="People"
        title="Customers"
        subtitle={`${customers.length} customers · ${money(totalSpent)} lifetime value`}
      />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Phone</th>
              <th>Location</th>
              <th className="num">Orders</th>
              <th className="num">Renders</th>
              <th>Last chat</th>
              <th className="num">Spent</th>
              <th>Joined</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {customers.map((c) => (
              <tr key={c.id}>
                <td>
                  <div className="product-cell">
                    <span className="avatar">{initials(c.name)}</span>
                    <div>
                      <div className="cell-strong">{c.name}</div>
                      <div className="cell-sub">{c.email}</div>
                    </div>
                  </div>
                </td>
                <td className="cell-muted">{c.phone}</td>
                <td className="cell-muted">{c.location}</td>
                <td className="num">{c.orders}</td>
                <td className="num">{c.renders}</td>
                <td className="cell-muted">{c.lastChat}</td>
                <td className="num serif-num">{money(c.spent)}</td>
                <td className="cell-muted">{c.joined}</td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="View customer"><EyeIcon /></button>
                    <button className="icon-btn" aria-label="More"><DotsIcon /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
