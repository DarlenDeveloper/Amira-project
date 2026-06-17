import { useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { EyeIcon, DotsIcon } from '../components/icons.jsx';
import { useCollection } from '../db.js';
import { titleCase } from '../utils.js';

const APPOINTMENT_STATUSES = ['requested', 'confirmed', 'completed', 'cancelled'];

export default function Appointments() {
  const [filter, setFilter] = useState('all');
  const { data } = useCollection('appointments');

  const appointments = useMemo(() => {
    return [...data].sort((a, b) => {
      const at = a.createdAt?.toMillis?.() ?? 0;
      const bt = b.createdAt?.toMillis?.() ?? 0;
      return bt - at;
    });
  }, [data]);

  const counts = useMemo(() => {
    const c = {};
    for (const s of APPOINTMENT_STATUSES) c[s] = appointments.filter((a) => a.status === s).length;
    return c;
  }, [appointments]);

  const rows = filter === 'all' ? appointments : appointments.filter((a) => a.status === filter);

  const options = [
    { value: 'all', label: 'All' },
    ...APPOINTMENT_STATUSES.map((s) => ({ value: s, label: titleCase(s), count: counts[s] })),
  ];

  return (
    <div className="page">
      <PageHeader
        eyebrow="Scheduling"
        title="Appointments"
        subtitle={`${appointments.length} booking requests`}
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Ref</th>
              <th>Customer</th>
              <th>Type</th>
              <th>Date</th>
              <th>Time</th>
              <th>Status</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((a) => (
              <tr key={a.id}>
                <td className="mono">{a.appointmentId}</td>
                <td>
                  <div className="cell-strong">{a.customer}</div>
                  <div className="cell-sub">{a.note}</div>
                </td>
                <td className="cell-muted">{a.type}</td>
                <td className="cell-muted">{a.date || '—'}</td>
                <td className="cell-muted">{a.time || '—'}</td>
                <td><StatusBadge status={a.status} /></td>
                <td className="right">
                  <div className="row-actions">
                    <button className="icon-btn" aria-label="View appointment"><EyeIcon /></button>
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
