import { useState, useEffect, useMemo } from 'react';
import { useShop } from './context/ShopContext.jsx';
import MaterialCard from './components/MaterialCard.jsx';
import HeroSection from './components/HeroSection.jsx';
import CategoryStrip from './components/CategoryStrip.jsx';
import ProductDetail from './components/ProductDetail.jsx';
import CartDrawer from './components/CartDrawer.jsx';
import AuthModal from './components/AuthModal.jsx';
import ProfilePage from './components/ProfilePage.jsx';
import CompleteProfileModal from './components/CompleteProfileModal.jsx';
import NotificationsPanel from './components/NotificationsPanel.jsx';
import { profileNeedsPhone } from './services/auth.js';
import { watchProfile, displayName } from './services/profile.js';
import { trackPageView } from './services/analytics.js';
import Navbar from './components/Navbar.jsx';

// Web shop home: hero, category strip, filter pills, the live product grid, a
// product detail overlay, plus the cart drawer and auth/checkout modal.
export default function ExplorePage() {
  const {
    products,
    productsLoading,
    productsError,
    categories,
    cartCount,
    user,
    hasAccount,
    notificationUnreadCount,
  } = useShop();

  const [activeFilter, setActiveFilter] = useState('All');
  const [selected, setSelected] = useState(null);
  const [cartOpen, setCartOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [authState, setAuthState] = useState(null); // { reason, onSuccess } | null
  const [profile, setProfile] = useState(null);
  const [profileReady, setProfileReady] = useState(false);

  useEffect(() => {
    if (!user?.uid || !hasAccount) {
      setProfile(null);
      setProfileReady(false);
      return undefined;
    }
    setProfileReady(false);
    return watchProfile(user.uid, (data) => {
      setProfile(data);
      setProfileReady(true);
    });
  }, [user?.uid, hasAccount]);

  const needsPhoneComplete =
    hasAccount && profileReady && profileNeedsPhone(profile) && !authState;

  const filters = useMemo(() => ['All', ...categories], [categories]);

  // Keep the active filter valid as the live category set changes.
  useEffect(() => {
    if (activeFilter !== 'All' && !categories.includes(activeFilter)) {
      setActiveFilter('All');
    }
  }, [categories, activeFilter]);

  const visible = useMemo(
    () =>
      activeFilter === 'All'
        ? products
        : products.filter((p) => p.category === activeFilter),
    [products, activeFilter],
  );

  // Lock background scroll while any overlay is open.
  useEffect(() => {
    const open = selected || cartOpen || notifOpen || profileOpen || authState || needsPhoneComplete;
    document.body.style.overflow = open ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [selected, cartOpen, notifOpen, profileOpen, authState, needsPhoneComplete]);

  const requireAccount = (reason, onSuccess) => setAuthState({ reason, onSuccess });

  const accountLabel = hasAccount ? displayName(user, profile) : '';

  // Analytics — pages and products visited (guests + members).
  useEffect(() => {
    if (!user?.uid) return;
    trackPageView(user, { page: 'explore' });
  }, [user?.uid]);

  useEffect(() => {
    if (!user?.uid || !selected) return;
    trackPageView(user, {
      page: 'product',
      productId: selected.id,
      productName: selected.name,
      category: selected.category,
    });
  }, [user?.uid, selected?.id]);

  useEffect(() => {
    if (!user?.uid || activeFilter === 'All') return;
    trackPageView(user, { page: 'category', category: activeFilter });
  }, [user?.uid, activeFilter]);

  useEffect(() => {
    if (!user?.uid || !cartOpen) return;
    trackPageView(user, { page: 'cart' });
  }, [user?.uid, cartOpen]);

  useEffect(() => {
    if (!user?.uid || !profileOpen) return;
    trackPageView(user, { page: 'profile' });
  }, [user?.uid, profileOpen]);

  useEffect(() => {
    if (!user?.uid || !notifOpen) return;
    trackPageView(user, { page: 'notifications' });
  }, [user?.uid, notifOpen]);

  return (
    <div className="explore">
      <Navbar />
      <HeroSection />

      <div className="explore-inner">
        <header className="explore-header">
          <h1 className="explore-title">Explore</h1>
          <div className="header-actions">
            {hasAccount ? (
              <button
                type="button"
                className="account-chip account-chip--signed-in"
                onClick={() => setProfileOpen(true)}
                title="Open profile"
                aria-label={`Signed in as ${accountLabel}. Open profile`}
              >
                <span className="account-avatar" aria-hidden="true">
                  {user?.photoURL ? (
                    <img src={user.photoURL} alt="" className="account-avatar-img" />
                  ) : (
                    accountLabel.charAt(0).toUpperCase()
                  )}
                </span>
                <span className="account-label">{accountLabel?.split(' ')[0]}</span>
                <span className="account-status-dot" aria-hidden="true" />
              </button>
            ) : (
              <button
                type="button"
                className="account-chip"
                onClick={() => requireAccount('Sign in to track your orders.', null)}
              >
                Sign in
              </button>
            )}
            <button
              type="button"
              className="notif-button"
              aria-label="Open notifications"
              onClick={() => setNotifOpen(true)}
            >
              <NotifIcon />
              {notificationUnreadCount > 0 && (
                <span className="notif-count">{notificationUnreadCount}</span>
              )}
            </button>
            <button type="button" className="cart-button" aria-label="Open cart" onClick={() => setCartOpen(true)}>
              <CartIcon />
              {cartCount > 0 && <span className="cart-count">{cartCount}</span>}
            </button>
          </div>
        </header>

        <CategoryStrip
          products={products}
          active={activeFilter}
          onSelect={setActiveFilter}
        />

        {filters.length > 1 && (
          <div className="filter-row" role="tablist" aria-label="Filter materials">
            {filters.map((label) => {
              const active = label === activeFilter;
              return (
                <button
                  key={label}
                  type="button"
                  role="tab"
                  aria-selected={active}
                  className={`filter-pill${active ? ' filter-pill--active' : ''}`}
                  onClick={() => setActiveFilter(label)}
                >
                  {label}
                </button>
              );
            })}
          </div>
        )}

        <main id="explore-grid" className="material-grid">
          {productsError ? (
            <p className="grid-message">
              We couldn&apos;t load the collection right now. Please refresh in a moment.
            </p>
          ) : productsLoading ? (
            Array.from({ length: 6 }).map((_, i) => <CardSkeleton key={i} />)
          ) : visible.length === 0 ? (
            <p className="grid-message">No products in this category yet.</p>
          ) : (
            visible.map((m) => (
              <MaterialCard key={m.id} data={m} onOpen={() => setSelected(m)} />
            ))
          )}
        </main>
      </div>

      {selected && (
        <ProductDetail
          data={selected}
          related={products}
          onClose={() => setSelected(null)}
          onSelect={setSelected}
          onOpenCart={() => setCartOpen(true)}
          onRequireAccount={requireAccount}
        />
      )}

      {cartOpen && (
        <CartDrawer onClose={() => setCartOpen(false)} onRequireAccount={requireAccount} />
      )}

      {notifOpen && <NotificationsPanel onClose={() => setNotifOpen(false)} />}

      {profileOpen && <ProfilePage onClose={() => setProfileOpen(false)} />}

      {needsPhoneComplete && (
        <CompleteProfileModal userName={accountLabel} />
      )}

      {authState && (
        <AuthModal
          reason={authState.reason}
          onClose={() => setAuthState(null)}
          onSuccess={authState.onSuccess}
        />
      )}
    </div>
  );
}

function CardSkeleton() {
  return (
    <div className="material-card material-card--skeleton" aria-hidden="true">
      <div className="card-image-wrap skeleton-box" />
      <div className="skeleton-line" />
      <div className="skeleton-line skeleton-line--short" />
    </div>
  );
}

function CartIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4H6zM3.8 6 6 3h12l2.2 3H3.8z" />
    </svg>
  );
}

function NotifIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 22a2.5 2.5 0 0 0 2.45-2h-4.9A2.5 2.5 0 0 0 12 22Zm7-6V11a7 7 0 0 0-6-6.92V3a1 1 0 1 0-2 0v1.08A7 7 0 0 0 5 11v5l-2 2v1h18v-1l-2-2Z" />
    </svg>
  );
}
