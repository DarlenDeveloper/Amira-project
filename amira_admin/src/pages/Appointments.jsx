import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import FilterPills from '../components/FilterPills.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { EyeIcon } from '../components/icons.jsx';
import { useCollection, updateDocById } from '../db.js';
import { titleCase } from '../utils.js';

const APPOINTMENT_STATUSES = ['requested', 'confirmed', 'completed', 'cancelled'];

function isPhoneCredentialEmail(email) {
  return String(email || '').includes('@phone.amira.app');
}

/** Best-effort phone + email for display and editing. */
function resolveContact(appointment, userByUid) {
  const profile = userByUid[appointment.uid];
  let phone = String(appointment.phone || profile?.phone || '').trim();
  let email = String(appointment.email || '').trim();

  if (!phone && email && !email.includes('@')) {
    phone = email;
    email = String(profile?.email || '').trim();
  }
  if (isPhoneCredentialEmail(email)) {
    email = String(profile?.email || '').trim();
    if (isPhoneCredentialEmail(email)) email = '';
  }
  if (!email && profile?.email && !isPhoneCredentialEmail(profile.email)) {
    email = String(profile.email).trim();
  }

  return { phone, email };
}

export default function Appointments() {
  const [filter, setFilter] = useState('all');
  const [activeId, setActiveId] = useState(null);
  const [form, setForm] = useState(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const { data } = useCollection('appointments');
  const { data: users } = useCollection('users');

  const userByUid = useMemo(
    () => Object.fromEntries(users.map((u) => [u.id, u])),
    [users],
  );

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
  const selected = appointments.find((a) => a.id === activeId);

  useEffect(() => {
    if (!activeId) {
      setForm(null);
      return;
    }
    const appt = appointments.find((a) => a.id === activeId);
    if (!appt) {
      setForm(null);
      return;
    }
    const { phone, email } = resolveContact(appt, userByUid);
    setForm({
      phone,
      email,
      date: appt.date || '',
      time: appt.time || '',
      status: appt.status || 'requested',
    });
    setSaveError('');
    // Intentionally only when the selected row changes — not on every Firestore tick.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeId]);

  const options = [
    { value: 'all', label: 'All' },
    ...APPOINTMENT_STATUSES.map((s) => ({ value: s, label: titleCase(s), count: counts[s] })),
  ];

  async function handleSave(e) {
    e.preventDefault();
    if (!selected || !form) return;
    setSaving(true);
    setSaveError('');
    try {
      await updateDocById('appointments', selected.id, {
        phone: form.phone.trim(),
        email: form.email.trim(),
        date: form.date.trim(),
        time: form.time.trim(),
        status: form.status,
      });
    } catch (err) {
      setSaveError(err.message || 'Could not save appointment.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="page">
      <PageHeader
        eyebrow="Scheduling"
        title="Appointments"
        subtitle={`${appointments.length} booking requests`}
      />

      <FilterPills options={options} active={filter} onChange={setFilter} />

      <div className="table-card">
        <div className="table-scroll">
          <table className="data-table data-table--wide">
          <thead>
            <tr>
              <th>Ref</th>
              <th>Customer</th>
              <th>Phone</th>
              <th>Email</th>
              <th>Type</th>
              <th>Date</th>
              <th>Time</th>
              <th>Status</th>
              <th className="right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((a) => {
              const { phone, email } = resolveContact(a, userByUid);
              return (
                <tr
                  key={a.id}
                  className={a.id === activeId ? 'row--active' : ''}
                  onClick={() => setActiveId(a.id)}
                  style={{ cursor: 'pointer' }}
                >
                  <td className="mono">{a.appointmentId}</td>
                  <td>
                    <div className="cell-strong">{a.customer}</div>
                    <div className="cell-sub">{a.note}</div>
                  </td>
                  <td className="cell-muted">{phone || '—'}</td>
                  <td className="cell-muted">{email || '—'}</td>
                  <td className="cell-muted">{a.type}</td>
                  <td className="cell-muted">{a.date || '—'}</td>
                  <td className="cell-muted">{a.time || '—'}</td>
                  <td><StatusBadge status={a.status} /></td>
                  <td className="right">
                    <div className="row-actions">
                      <button
                        type="button"
                        className="icon-btn"
                        aria-label="View appointment"
                        onClick={(e) => {
                          e.stopPropagation();
                          setActiveId(a.id);
                        }}
                      >
                        <EyeIcon />
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
          </table>
          {rows.length === 0 && <p className="empty">No appointments yet.</p>}
        </div>
      </div>

      {selected && form && (
        <aside className="drawer-panel" style={{ marginTop: 24 }}>
          <h2 className="agent-recent-title">{selected.appointmentId} — {selected.customer}</h2>
          <p className="cell-muted" style={{ marginBottom: 16 }}>{selected.type} · {selected.note}</p>

          <form onSubmit={handleSave} className="form-stack">
            <div className="form-row">
              <label className="form-field">
                <span>Phone</span>
                <input
                  type="tel"
                  value={form.phone}
                  onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
                  placeholder="+256 700 123 456"
                />
              </label>
              <label className="form-field">
                <span>Email</span>
                <input
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                  placeholder="customer@example.com"
                />
              </label>
            </div>

            <div className="form-row">
              <label className="form-field">
                <span>Date</span>
                <input
                  type="text"
                  value={form.date}
                  onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
                  placeholder="Jun 18, 2026"
                />
              </label>
              <label className="form-field">
                <span>Time</span>
                <input
                  type="text"
                  value={form.time}
                  onChange={(e) => setForm((f) => ({ ...f, time: e.target.value }))}
                  placeholder="10:00"
                />
              </label>
            </div>

            <label className="form-field">
              <span>Status</span>
              <select
                value={form.status}
                onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}
              >
                {APPOINTMENT_STATUSES.map((s) => (
                  <option key={s} value={s}>{titleCase(s)}</option>
                ))}
              </select>
            </label>

            {saveError && <p className="form-error">{saveError}</p>}

            <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
              <button type="submit" className="primary-btn" disabled={saving}>
                {saving ? 'Saving…' : 'Save contact & schedule'}
              </button>
              <button
                type="button"
                className="ghost-btn"
                onClick={() => setActiveId(null)}
              >
                Close
              </button>
            </div>
          </form>
        </aside>
      )}
    </div>
  );
}
