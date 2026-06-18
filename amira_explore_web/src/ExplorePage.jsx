import { useState, useEffect, useMemo } from 'react';
import { useShop } from './context/ShopContext.jsx';
import MaterialCard from './components/MaterialCard.jsx';
import HeroSection from './components/HeroSection.jsx';
import CategoryStrip from './components/CategoryStrip.jsx';
import ProductDetail from './components/ProductDetail.jsx';
import CartDrawer from './components/CartDrawer.jsx';
import AuthModal from './components/AuthModal.jsx';
import ProfilePage from './components/ProfilePage.jsx';
import { displayName } from './services/profile.js';

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
  } = useShop();

  const [activeFilter, setActiveFilter] = useState('All');
  const [selected, setSelected] = useState(null);
  const [cartOpen, setCartOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [authState, setAuthState] = useState(null); // { reason, onSuccess } | null

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
    const open = selected || cartOpen || profileOpen || authState;
    document.body.style.overflow = open ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [selected, cartOpen, profileOpen, authState]);

  const requireAccount = (reason, onSuccess) => setAuthState({ reason, onSuccess });

  const accountLabel = hasAccount ? displayName(user, null) : '';

  return (
    <div className="explore">
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

      {profileOpen && <ProfilePage onClose={() => setProfileOpen(false)} />}

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
