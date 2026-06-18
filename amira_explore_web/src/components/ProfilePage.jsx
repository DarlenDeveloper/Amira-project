import { useEffect, useState } from 'react';
import { useShop } from '../context/ShopContext.jsx';
import { signOut } from '../services/auth.js';
import { watchProfile, displayName, displayEmail } from '../services/profile.js';
import { watchMyOrders } from '../services/orders.js';
import { formatUgx } from '../lib/currency.js';

const STATUS_LABEL = {
  pending: 'Pending',
  confirmed: 'Confirmed',
  processing: 'Processing',
  shipped: 'Shipped',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

// Signed-in account sheet: profile summary, order history, sign out.
export default function ProfilePage({ onClose }) {
  const { user, hasAccount } = useShop();
  const [profile, setProfile] = useState(null);
  const [orders, setOrders] = useState([]);
  const [signingOut, setSigningOut] = useState(false);

  useEffect(() => {
    if (!user?.uid || !hasAccount) return undefined;
    return watchProfile(user.uid, setProfile);
  }, [user?.uid, hasAccount]);

  useEffect(() => {
    if (!user?.uid || !hasAccount) {
      setOrders([]);
      return undefined;
    }
    return watchMyOrders(user.uid, setOrders);
  }, [user?.uid, hasAccount]);

  const name = displayName(user, profile);
  const email = displayEmail(user, profile);
  const photo = profile?.photoUrl || user?.photoURL;
  const initial = name.charAt(0).toUpperCase();

  const handleSignOut = async () => {
    setSigningOut(true);
    try {
      await signOut();
      onClose();
    } finally {
      setSigningOut(false);
    }
  };

  if (!hasAccount) {
    return null;
  }

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <aside
        className="profile-drawer"
        role="dialog"
        aria-modal="true"
        aria-label="Your profile"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="profile-head">
          <h2 className="profile-heading">Profile</h2>
          <button type="button" className="circle-btn" aria-label="Close profile" onClick={onClose}>
            ×
          </button>
        </header>

        <div className="profile-body">
          <div className="profile-card">
            {photo ? (
              <img className="profile-avatar profile-avatar--photo" src={photo} alt="" />
            ) : (
              <span className="profile-avatar" aria-hidden="true">
                {initial}
              </span>
            )}
            <div className="profile-identity">
              <p className="profile-name">{name}</p>
              {email && <p className="profile-email">{email}</p>}
              <span className="profile-badge">Signed in</span>
            </div>
          </div>

          {profile?.address && (
            <section className="profile-section">
              <h3 className="profile-section-title">Delivery address</h3>
              <p className="profile-address">{profile.address}</p>
            </section>
          )}

          <section className="profile-section">
            <h3 className="profile-section-title">Your orders</h3>
            {orders.length === 0 ? (
              <p className="profile-empty">No orders yet. Items you checkout will appear here.</p>
            ) : (
              <ul className="profile-orders">
                {orders.map((order) => (
                  <li key={order.id} className="profile-order">
                    <div className="profile-order-top">
                      <span className="profile-order-ref">{order.orderId}</span>
                      <span className={`profile-order-status profile-order-status--${order.status}`}>
                        {STATUS_LABEL[order.status] || order.status}
                      </span>
                    </div>
                    <p className="profile-order-meta">
                      {order.itemCount} item{order.itemCount === 1 ? '' : 's'} · {formatUgx(order.total)}
                    </p>
                    {order.createdAt && (
                      <time className="profile-order-date" dateTime={order.createdAt.toISOString()}>
                        {order.createdAt.toLocaleDateString(undefined, {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </time>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <footer className="profile-foot">
          <button
            type="button"
            className="profile-signout"
            onClick={handleSignOut}
            disabled={signingOut}
          >
            {signingOut ? 'Signing out…' : 'Sign out'}
          </button>
        </footer>
      </aside>
    </div>
  );
}
