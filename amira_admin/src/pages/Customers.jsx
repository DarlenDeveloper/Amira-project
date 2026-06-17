import { useMemo } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { useCollection, formatMonth } from '../db.js';
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

  // Customers = user profiles enriched with order aggregates (count + spend).
  const customers = useMemo(() => {
    const byUid = {};
    for (const o of orders) {
      if (!o.uid) continue;
      const agg = byUid[o.uid] ?? { count: 0, spent: 0 };
      agg.count += 1;
      agg.spent += o.total || 0;
      byUid[o.uid] = agg;
    }
    return users.map((u) => {
      const agg = byUid[u.id] ?? { count: 0, spent: 0 };
      return {
        id: u.id,
        name: u.name || u.email || u.phone || 'Amira Member',
        email: u.email || u.phone || '',
        phone: u.phone || '—',
        location: u.address || '—',
        orders: agg.count,
        spent: agg.spent,
        joined: formatMonth(u.createdAt) || '—',
      };
    });
  }, [users, orders]);

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
