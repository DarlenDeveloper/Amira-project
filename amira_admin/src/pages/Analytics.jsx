import { useMemo } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import { useCollection, usePaginatedCollection, formatDateTime } from '../db.js';
import { titleCase } from '../utils.js';

const PAGE_LABELS = {
  explore: 'Explore shop',
  product: 'Product detail',
  category: 'Category filter',
  cart: 'Cart',
  profile: 'Profile',
  notifications: 'Notifications',
};

export default function Analytics() {
  const { data: users } = useCollection('users');
  const { data: events, loading, hasMore, loadMore, refresh } = usePaginatedCollection(
    'pageViews',
    { orderByField: 'createdAt', orderDir: 'desc', pageSize: 200 },
  );

  const userByUid = useMemo(
    () => Object.fromEntries(users.map((u) => [u.id, u])),
    [users],
  );

  const pageCounts = useMemo(() => {
    const counts = {};
    for (const e of events) {
      const key = e.page || 'unknown';
      counts[key] = (counts[key] || 0) + 1;
    }
    return Object.entries(counts).sort((a, b) => b[1] - a[1]);
  }, [events]);

  const productCounts = useMemo(() => {
    const byId = {};
    for (const e of events) {
      if (!e.productId) continue;
      if (!byId[e.productId]) {
        byId[e.productId] = {
          productId: e.productId,
          productName: e.productName || e.productId,
          views: 0,
        };
      }
      byId[e.productId].views += 1;
      if (e.productName) byId[e.productId].productName = e.productName;
    }
    return Object.values(byId).sort((a, b) => b.views - a.views);
  }, [events]);

  const uniqueVisitors = useMemo(() => new Set(events.map((e) => e.uid)).size, [events]);

  const visitorLabel = (e) => {
    const profile = userByUid[e.uid];
    if (profile?.name) return profile.name;
    if (profile?.email) return profile.email;
    if (profile?.phone) return profile.phone;
    return `${String(e.uid).slice(0, 8)}…`;
  };

  return (
    <div className="page">
      <PageHeader
        eyebrow="Insights"
        title="Analytics"
        subtitle="Pages and products visited on the web shop"
        action={(
          <button type="button" className="ghost-btn" onClick={refresh}>
            Refresh
          </button>
        )}
      />

      <div className="stat-grid">
        <div className="stat-card">
          <span className="stat-label">Total views</span>
          <span className="stat-value serif-num">{events.length}</span>
          <span className="stat-foot">Loaded events</span>
        </div>
        <div className="stat-card">
          <span className="stat-label">Unique visitors</span>
          <span className="stat-value serif-num">{uniqueVisitors}</span>
          <span className="stat-foot">Guests + members</span>
        </div>
        <div className="stat-card">
          <span className="stat-label">Products viewed</span>
          <span className="stat-value serif-num">{productCounts.length}</span>
          <span className="stat-foot">Distinct products</span>
        </div>
        <div className="stat-card">
          <span className="stat-label">Page types</span>
          <span className="stat-value serif-num">{pageCounts.length}</span>
          <span className="stat-foot">Distinct screens</span>
        </div>
      </div>

      <div className="overview-cols">
        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Pages visited</h2>
          </div>
          <div className="table-card table-card--flush">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Page</th>
                  <th className="right">Views</th>
                </tr>
              </thead>
              <tbody>
                {pageCounts.map(([page, count]) => (
                  <tr key={page}>
                    <td className="cell-strong">{PAGE_LABELS[page] || titleCase(page)}</td>
                    <td className="num">{count}</td>
                  </tr>
                ))}
                {pageCounts.length === 0 && (
                  <tr><td colSpan={2} className="cell-muted">No page views yet.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        <section className="panel">
          <div className="panel-head">
            <h2 className="panel-title">Products visited</h2>
          </div>
          <div className="table-card table-card--flush">
            <div className="table-scroll">
              <table className="data-table data-table--wide">
                <thead>
                  <tr>
                    <th>Product</th>
                    <th className="right">Views</th>
                  </tr>
                </thead>
                <tbody>
                  {productCounts.map((p) => (
                    <tr key={p.productId}>
                      <td className="cell-strong">{p.productName}</td>
                      <td className="num">{p.views}</td>
                    </tr>
                  ))}
                  {productCounts.length === 0 && (
                    <tr><td colSpan={2} className="cell-muted">No product views yet.</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>

      <section className="panel" style={{ marginTop: 24 }}>
        <div className="panel-head">
          <h2 className="panel-title">Recent visits</h2>
        </div>
        <div className="table-card">
          <div className="table-scroll">
            <table className="data-table data-table--wide">
              <thead>
                <tr>
                  <th>When</th>
                  <th>Visitor</th>
                  <th>Type</th>
                  <th>Page</th>
                  <th>Product / category</th>
                  <th>Source</th>
                </tr>
              </thead>
              <tbody>
                {events.map((e) => (
                  <tr key={e.id}>
                    <td className="cell-muted">{formatDateTime(e.createdAt)}</td>
                    <td className="cell-strong">{visitorLabel(e)}</td>
                    <td>
                      <span className={`pill${e.isGuest ? '' : ' pill--active'}`}>
                        {e.isGuest ? 'Guest' : 'Member'}
                      </span>
                    </td>
                    <td>{PAGE_LABELS[e.page] || e.page || '—'}</td>
                    <td className="cell-muted">
                      {e.productName || e.category || '—'}
                    </td>
                    <td className="cell-muted">{e.source || 'web'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {loading && <p className="empty">Loading…</p>}
            {!loading && events.length === 0 && (
              <p className="empty">No visits recorded yet. Browse the web shop to populate this feed.</p>
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
      </section>
    </div>
  );
}
