import { categories } from '../data/materials.js';

// Horizontal "Shop by Category" strip — rounded image tiles with a label.
export default function CategoryStrip() {
  return (
    <section className="category-section" aria-label="Shop by category">
      <h2 className="section-heading">Shop by Category</h2>
      <div className="category-row">
        {categories.map((c) => (
          <button type="button" className="category-card" key={c.name}>
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
