import PageHeader from '../components/PageHeader.jsx';
import { notifications } from '../data/notifications.js';

const TYPE_LABEL = {
  collection: 'Collection',
  offer: 'Offer',
  order: 'Order',
  design: 'Design',
};

export default function Notifications() {
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
                <span>{n.delivered.toLocaleString()} delivered</span>
              </div>
            </div>
            <span className="notif-time">{n.sent}</span>
          </article>
        ))}
      </div>
    </div>
  );
}
