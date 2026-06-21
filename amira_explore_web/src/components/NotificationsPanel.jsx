import { useEffect, useMemo, useState } from 'react';
import { useShop } from '../context/ShopContext.jsx';
import {
  watchNotifications,
  watchReadIds,
  markNotificationRead,
  formatTimeAgo,
  TYPE_STYLE,
} from '../services/notifications.js';

// Slide-in notifications feed — works for guests (anonymous) and signed-in shoppers.
export default function NotificationsPanel({ onClose }) {
  const { user } = useShop();
  const uid = user?.uid ?? null;
  const [items, setItems] = useState([]);
  const [readIds, setReadIds] = useState(new Set());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const unsubFeed = watchNotifications(
      uid,
      (list) => {
        setItems(list);
        setLoading(false);
      },
      () => setLoading(false),
    );
    const unsubRead = watchReadIds(uid, setReadIds);
    return () => {
      unsubFeed();
      unsubRead();
    };
  }, [uid]);

  const unreadCount = useMemo(
    () => items.filter((n) => !readIds.has(n.id)).length,
    [items, readIds],
  );

  const markRead = async (id) => {
    if (!uid) return;
    setReadIds((prev) => new Set(prev).add(id));
    try {
      await markNotificationRead(uid, id);
    } catch (err) {
      console.error('[Amira] Mark notification read failed:', err?.code, err?.message);
    }
  };

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <aside
        className="notif-drawer"
        role="dialog"
        aria-modal="true"
        aria-label="Notifications"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="cart-head">
          <h2 className="cart-heading">
            Notifications
            {unreadCount > 0 && (
              <span className="notif-drawer-badge">{unreadCount}</span>
            )}
          </h2>
          <button type="button" className="circle-btn" aria-label="Close notifications" onClick={onClose}>
            ×
          </button>
        </header>

        <div className="notif-drawer-body">
          {loading ? (
            <p className="grid-message">Loading…</p>
          ) : items.length === 0 ? (
            <div className="notif-empty">
              <div className="notif-empty-icon" aria-hidden="true">🔔</div>
              <p className="notif-empty-title">No notifications yet</p>
              <p className="notif-empty-body">We&apos;ll let you know when something arrives.</p>
            </div>
          ) : (
            <ul className="notif-feed">
              {items.map((n) => {
                const isRead = readIds.has(n.id);
                const style = TYPE_STYLE[n.type] || TYPE_STYLE.collection;
                return (
                  <li key={n.id} className={`notif-item${isRead ? ' notif-item--read' : ''}`}>
                    <div className="notif-item-icon" aria-hidden="true">{style.emoji}</div>
                    <div className="notif-item-main">
                      <div className="notif-item-head">
                        <strong>{n.title}</strong>
                        {!isRead && <span className="notif-unread-dot" aria-label="Unread" />}
                      </div>
                      <p className="notif-item-body">{n.body}</p>
                      <div className="notif-item-foot">
                        <span>{style.label}</span>
                        <span>·</span>
                        <span>{formatTimeAgo(n.sentAt)}</span>
                      </div>
                    </div>
                    {!isRead && uid && (
                      <button
                        type="button"
                        className="notif-mark-read"
                        onClick={() => markRead(n.id)}
                      >
                        Mark read
                      </button>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </aside>
    </div>
  );
}
