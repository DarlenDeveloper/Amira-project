import { useState, useEffect } from 'react';
import { materials, filters } from './data/materials.js';
import MaterialCard from './components/MaterialCard.jsx';
import HeroSection from './components/HeroSection.jsx';
import CategoryStrip from './components/CategoryStrip.jsx';
import ProductDetail from './components/ProductDetail.jsx';

// Web port of the Flutter Explore screen: hero, category strip, filter pills,
// the 2-column material grid, and a product detail overlay on tap.
export default function ExplorePage() {
  const [activeFilter, setActiveFilter] = useState(0);
  const [selected, setSelected] = useState(null);

  // Lock background scroll while the detail overlay is open.
  useEffect(() => {
    document.body.style.overflow = selected ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [selected]);

  return (
    <div className="explore">
      <HeroSection />

      <div className="explore-inner">
        <header className="explore-header">
          <h1 className="explore-title">Explore</h1>
          <button type="button" className="cart-button" aria-label="Open cart">
            <CartIcon />
          </button>
        </header>

        <CategoryStrip />

        <div className="filter-row" role="tablist" aria-label="Filter materials">
          {filters.map((label, i) => {
            const active = i === activeFilter;
            return (
              <button
                key={label}
                type="button"
                role="tab"
                aria-selected={active}
                className={`filter-pill${active ? ' filter-pill--active' : ''}`}
                onClick={() => setActiveFilter(i)}
              >
                {label}
              </button>
            );
          })}
        </div>

        <main id="explore-grid" className="material-grid">
          {materials.map((m) => (
            <MaterialCard key={m.name} data={m} onOpen={() => setSelected(m)} />
          ))}
        </main>
      </div>

      {selected && <ProductDetail data={selected} onClose={() => setSelected(null)} />}
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
