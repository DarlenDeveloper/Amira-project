import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import OrderDetailModal from '../components/OrderDetailModal.jsx';
import { EyeIcon } from '../components/icons.jsx';
import { useCollection, formatDate } from '../db.js';
import { money, titleCase } from '../utils.js';

const ORDER_STATUSES = [
  'pending', 'processing', 'paid', 'shipped', 'delivered', 'cancelled',
];

export default function Orders() {
  const [filter, setFilter] = useState('all');
  const [activeId, setActiveId] = useState(null);
  const { data } = useCollection('orders');

  const orders = useMemo(() => {
    return [...data].sort((a, b) => {
      const at = a.createdAt?.toMillis?.() ?? 0;
      const bt = b.createdAt?.toMillis?.() ?? 0;
      return bt - at;
    });
  }, [data]);

  const counts = useMemo(() => {
    const c = {};
    for (const s of ORDER_STATUSES) c[s] = orders.filter((o) => o.status === s).length;
    return c;
  }, [orders]);

  const total = useMemo(() => orders.reduce((sum, o) => sum + (o.total || 0), 0), [orders]);
  const rows = filter === 'all' ? orders : orders.filter((o) => o.status === filter);
  const active = orders.find((o) => o.id === activeId);

  const options = [
    { value: 'all', label: 'All' },
    ...ORDER_STATUSES.map((s) => ({ value: s, label: titleCase(s), count: counts[s] })),
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
        <div className="table-scroll">
          <table className="data-table data-table--wide">
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
                <tr
                  key={o.id}
                  className={o.id === activeId ? 'row--active' : ''}
                  onClick={() => setActiveId(o.id)}
                  style={{ cursor: 'pointer' }}
                >
                  <td className="mono">{o.orderId}</td>
                  <td>
                    <div className="cell-strong">{o.customer}</div>
                    <div className="cell-sub">{o.email}</div>
                  </td>
                  <td className="cell-muted">{formatDate(o.createdAt)}</td>
                  <td className="num">{o.itemCount}</td>
                  <td><StatusBadge status={o.status} /></td>
                  <td className="num serif-num">{money(o.total)}</td>
                  <td className="right">
                    <div className="row-actions">
                      <button
                        type="button"
                        className="icon-btn"
                        aria-label="View order"
                        onClick={(e) => {
                          e.stopPropagation();
                          setActiveId(o.id);
                        }}
                      >
                        <EyeIcon />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length === 0 && <p className="empty">No orders yet.</p>}
        </div>
      </div>

      {active && (
        <OrderDetailModal
          order={active}
          onClose={() => setActiveId(null)}
        />
      )}
    </div>
  );
}
