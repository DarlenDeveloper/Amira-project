import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import PageHeader from '../components/PageHeader.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import Thumb from '../components/Thumb.jsx';
import { usePaginatedCollection, formatDateTime } from '../db.js';

const STATUS_TABS = [
  { id: 'all', label: 'All' },
  { id: 'completed', label: 'Completed' },
  { id: 'failed', label: 'Failed' },
  { id: 'in-progress', label: 'In progress' },
];

const inProgressStatuses = ['uploading', 'ready', 'generating'];

export default function Renders() {
  const [tab, setTab] = useState('all');
  const [active, setActive] = useState(null);

  const whereClause = useMemo(() => {
    if (tab === 'all') return undefined;
    if (tab === 'in-progress') return ['status', 'in', inProgressStatuses];
    return ['status', '==', tab];
  }, [tab]);

  const { data, loading, error, hasMore, loadMore, refresh } = usePaginatedCollection(
    'renders',
    {
      whereClause: tab === 'in-progress'
        ? undefined
        : whereClause,
      orderByField: 'createdAt',
      orderDir: 'desc',
      pageSize: 50,
    },
  );

  const filtered = useMemo(() => {
    if (tab !== 'in-progress') return data;
    return data.filter((r) => inProgressStatuses.includes(r.status));
  }, [data, tab]);

  const selected = filtered.find((r) => r.id === active);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Visual Studio"
        title="Renders"
        subtitle={`${filtered.length} session(s) shown`}
        action={
          <button type="button" className="ghost-btn" onClick={refresh}>
            Refresh
          </button>
        }
      />

      <div className="filter-pills" style={{ marginBottom: 16 }}>
        {STATUS_TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            className={`pill${tab === t.id ? ' pill--active' : ''}`}
            onClick={() => {
              setTab(t.id);
              setActive(null);
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {error && <p className="form-error">{error.message}</p>}

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Status</th>
              <th>Materials</th>
              <th>Prompt</th>
              <th>Preview</th>
              <th>Created</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr
                key={r.id}
                className={r.id === active ? 'row--active' : ''}
                onClick={() => setActive(r.id)}
                style={{ cursor: 'pointer' }}
              >
                <td>
                  <div className="cell-strong">{r.customer || '—'}</div>
                  <div className="cell-sub">{r.email || ''}</div>
                </td>
                <td><StatusBadge status={r.status} /></td>
                <td className="cell-muted">
                  {(r.materialNames || []).join(', ') || '—'}
                </td>
                <td className="cell-muted">
                  {(r.prompt || '').slice(0, 40)}{(r.prompt || '').length > 40 ? '…' : ''}
                </td>
                <td>
                  <Thumb src={r.resultUrl || r.roomImageUrl} className="thumb-sm" />
                </td>
                <td className="cell-muted">{formatDateTime(r.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && <p className="empty">Loading…</p>}
        {!loading && filtered.length === 0 && (
          <p className="empty">No renders yet.</p>
        )}
        {hasMore && !loading && (
          <div style={{ padding: 16, textAlign: 'center' }}>
            <button type="button" className="ghost-btn" onClick={loadMore}>
              Load more
            </button>
          </div>
        )}
      </div>

      {selected && (
        <aside className="drawer-panel" style={{ marginTop: 24 }}>
          <h2 className="agent-recent-title">Session detail</h2>
          <p><strong>Status:</strong> {selected.status}</p>
          {selected.error && (
            <p className="form-error"><strong>Error:</strong> {selected.error}</p>
          )}
          <p className="cell-muted"><strong>Room path:</strong> {selected.roomStoragePath || '—'}</p>
          <p className="cell-muted"><strong>Result path:</strong> {selected.resultStoragePath || '—'}</p>
          <p className="cell-muted"><strong>Source:</strong> {selected.source || '—'}</p>
          <div style={{ display: 'flex', gap: 12, marginTop: 12, flexWrap: 'wrap' }}>
            {selected.roomImageUrl && (
              <img src={selected.roomImageUrl} alt="Room" style={{ maxWidth: 200, borderRadius: 8 }} />
            )}
            {selected.resultUrl && (
              <img src={selected.resultUrl} alt="Result" style={{ maxWidth: 200, borderRadius: 8 }} />
            )}
          </div>
          {selected.uid && (
            <p style={{ marginTop: 12 }}>
              <Link to="/customers">View customers</Link>
              {' · '}
              <span className="cell-muted">uid: {selected.uid}</span>
            </p>
          )}
        </aside>
      )}
    </div>
  );
}
