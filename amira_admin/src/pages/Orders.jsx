import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { orders, orderStatuses } from '../data/orders.js';
import { money, titleCase } from '../utils.js';

export default function Orders() {
  const [filter, setFilter] = useState('all');

  const counts = useMemo(() => {
    const c = {};
    for (const s of orderStatuses) c[s] = orders.filter((o) => o.status === s).length;
    return c;
  }, []);

  const total = useMemo(() => orders.reduce((sum, o) => sum + o.total, 0), []);
  const rows = filter === 'all' ? orders : orders.filter((o) => o.status === filter);

  const options = [
    { value: 'all', label: 'All' },
    ...orderStatuses.map((s) => ({ value: s, label: titleCase(s), count: counts[s] })),
  ];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Sales"
        title="Orders"
        subtitle={`${orders.length} total · ${money(total)} processed`}
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Customer</th>
              <th>Date</th>
              <th className="num">Items</th>
              <th>Status</th>
              <th className="num">Total</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((o) => (
              <tr key={o.id}>
                <td className="mono">{o.id}</td>
                <td>
                  <div className="cell-strong">{o.customer}</div>
                  <div className="cell-sub">{o.email}</div>
                </td>
                <td className="cell-muted">{o.date}</td>
                <td className="num">{o.items}</td>
                <td><StatusBadge status={o.status} /></td>
                <td className="num serif-num">{money(o.total)}</td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="View order"><EyeIcon /></button>
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
