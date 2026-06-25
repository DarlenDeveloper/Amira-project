import { Fragment, useMemo, useState } from 'react';
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
            {filtered.map((r) => {
              const isOpen = r.id === active;
              return (
                <Fragment key={r.id}>
                  <tr
                    className={isOpen ? 'row--active' : ''}
                    onClick={() => setActive(isOpen ? null : r.id)}
                    style={{ cursor: 'pointer' }}
                  >
                    <td>
                      <div className="cell-strong">
                        <span className={`row-caret${isOpen ? ' row-caret--open' : ''}`}>
                          ▸
                        </span>
                        {r.customer || '—'}
                      </div>
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
                  {isOpen && (
                    <tr className="render-detail-row">
                      <td className="render-detail-cell" colSpan={6}>
                        <div className="render-detail">
                          <div className="render-detail-imgs">
                            {r.roomImageUrl && (
                              <figure className="render-detail-fig">
                                <img src={r.roomImageUrl} alt="Room" className="render-detail-img" />
                                <figcaption>Room photo</figcaption>
                              </figure>
                            )}
                            {r.resultUrl && (
                              <figure className="render-detail-fig">
                                <img src={r.resultUrl} alt="Result" className="render-detail-img" />
                                <figcaption>AI render</figcaption>
                              </figure>
                            )}
                          </div>
                          {r.error && (
                            <p className="form-error"><strong>Error:</strong> {r.error}</p>
                          )}
                          <div className="render-detail-meta">
                            <div><span className="rd-label">Status</span><span className="rd-value">{r.status}</span></div>
                            <div><span className="rd-label">Source</span><span className="rd-value">{r.source || '—'}</span></div>
                            <div><span className="rd-label">Materials</span><span className="rd-value">{(r.materialNames || []).join(', ') || '—'}</span></div>
                            <div><span className="rd-label">Prompt</span><span className="rd-value">{r.prompt || '—'}</span></div>
                            <div><span className="rd-label">Room path</span><span className="rd-value">{r.roomStoragePath || '—'}</span></div>
                            <div><span className="rd-label">Result path</span><span className="rd-value">{r.resultStoragePath || '—'}</span></div>
                            {r.uid && (
                              <div><span className="rd-label">User ID</span><span className="rd-value">{r.uid}</span></div>
                            )}
                          </div>
                        </div>
                      </td>
                    </tr>
                  )}
                </Fragment>
              );
            })}
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
    </div>
  );
}
