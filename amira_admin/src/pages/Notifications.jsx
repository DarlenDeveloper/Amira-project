import { useMemo } from 'react';
import PageHeader from '../components/PageHeader.jsx';
import { useCollection, formatDate } from '../db.js';

const TYPE_LABEL = {
  collection: 'Collection',
  offer: 'Offer',
  order: 'Order',
  design: 'Design',
};

export default function Notifications() {
  const { data } = useCollection('notifications');

  const notifications = useMemo(() => {
    return [...data].sort((a, b) => {
      const at = a.sentAt?.toMillis?.() ?? 0;
      const bt = b.sentAt?.toMillis?.() ?? 0;
      return bt - at;
    });
  }, [data]);

  return (
    <div className="page">
      <PageHeader
        eyebrow="Engagement"
        title="Notifications"
        subtitle={`${notifications.length} sent`}
        action={<button className="primary-btn">+ New notification</button>}
      />

      <div className="notif-list">
        {notifications.map((n) => (
          <article key={n.id} className="notif-card">
            <div className="notif-main">
              <div className="notif-head">
                <span className="notif-title">{n.title}</span>
                <span className="notif-type">{TYPE_LABEL[n.type] ?? n.type}</span>
              </div>
              <p className="notif-body">{n.body}</p>
              <div className="notif-foot">
                <span>To: {n.audience}</span>
                <span className="dot-sep">·</span>
                <span>{(n.delivered ?? 0).toLocaleString()} delivered</span>
              </div>
            </div>
            <span className="notif-time">{formatDate(n.sentAt)}</span>
          </article>
        ))}
      </div>
    </div>
  );
}
