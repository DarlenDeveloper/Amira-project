import { useMemo } from 'react';

// Horizontal "Shop by Category" strip, built from the live catalogue: one tile
// per category using the first product image found for it. Tapping a tile
// filters the grid. Hidden when the catalogue has no categories yet.
export default function CategoryStrip({ products = [], active, onSelect }) {
  const categories = useMemo(() => {
    const map = new Map();
    for (const p of products) {
      if (p.category && !map.has(p.category)) {
        map.set(p.category, p.image);
      }
    }
    return [...map.entries()].map(([name, image]) => ({ name, image }));
  }, [products]);

  if (categories.length === 0) return null;

  return (
    <section className="category-section" aria-label="Shop by category">
      <h2 className="section-heading">Shop by Category</h2>
      <div className="category-row">
        {categories.map((c) => (
          <button
            type="button"
            className={`category-card${active === c.name ? ' category-card--active' : ''}`}
            key={c.name}
            onClick={() => onSelect?.(active === c.name ? 'All' : c.name)}
          >
            <div className="category-thumb">
              <img src={c.image} alt={c.name} loading="lazy" />
            </div>
            <span className="category-label">{c.name}</span>
          </button>
        ))}
      </div>
    </section>
  );
}
