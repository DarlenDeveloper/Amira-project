import { useState, useEffect, useMemo } from 'react';
import { materials } from '../data/materials.js';

// Web product page: image carousel (left) + specs & actions (right),
// then a "You might also like" row beneath.
export default function ProductDetail({ data, onClose, onSelect }) {
  const [qty, setQty] = useState(1);
  const [toast, setToast] = useState(null);

  const total = (data.value ?? 0) * qty;

  // Build a small gallery for the carousel. Each material currently ships one
  // image, so we pad with a couple of other speciality shots as placeholder
  // "additional views" until real per-product galleries exist.
  const gallery = useMemo(() => {
    const others = materials
      .filter((m) => m.image !== data.image)
      .slice(0, 2)
      .map((m) => m.image);
    return [data.image, ...others];
  }, [data]);

  // Related products (exclude the current one).
  const related = useMemo(
    () => materials.filter((m) => m.name !== data.name).slice(0, 4),
    [data],
  );

  // Reset quantity / scroll when switching products.
  useEffect(() => {
    setQty(1);
    document.querySelector('.detail-scroll')?.scrollTo({ top: 0 });
  }, [data]);

  const showToast = (msg) => {
    setToast(msg);
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => setToast(null), 1600);
  };

  return (
    <div className="detail" role="dialog" aria-modal="true" aria-label={data.name}>
      <div className="detail-scroll">
        <div className="detail-topbar">
          <button type="button" className="circle-btn" aria-label="Back" onClick={onClose}>
            <ArrowLeft />
          </button>
          <button
            type="button"
            className="circle-btn circle-btn--dark"
            aria-label="Add to cart"
            onClick={() => showToast(`${data.name} added to cart`)}
          >
            <Bag />
          </button>
        </div>

        <div className="detail-main">
          <Carousel images={gallery} alt={data.name} />

          <div className="detail-info">
            {data.badge && <span className="info-badge">{data.badge}</span>}
            <h2 className="info-name">{data.name}</h2>
            <p className="info-price">
              ${data.value} <span className="info-unit">/ {data.unit}</span>
            </p>

            <p className="info-about">{data.about}</p>

            {data.specs?.length > 0 && (
              <div className="spec-block">
                <h3 className="spec-title">Specifications</h3>
                <dl className="spec-list">
                  {data.specs.map((s) => (
                    <div className="spec-row" key={s.label}>
                      <dt className="spec-label">{s.label}</dt>
                      <dd className="spec-value">{s.value}</dd>
                    </div>
                  ))}
                </dl>
              </div>
            )}

            <div className="info-buy">
              <div className="info-qty">
                <span className="info-qty-label">Quantity</span>
                <div className="qty-stepper">
                  <button type="button" className="qty-btn" aria-label="Decrease" onClick={() => setQty((q) => (q > 1 ? q - 1 : q))}>
                    −
                  </button>
                  <span className="qty-value">{qty}</span>
                  <button type="button" className="qty-btn" aria-label="Increase" onClick={() => setQty((q) => q + 1)}>
                    +
                  </button>
                </div>
              </div>
              <div className="info-total">
                <span className="info-total-label">Total</span>
                <span className="info-total-value">${total}</span>
              </div>
            </div>

            <div className="info-actions">
              <button type="button" className="btn btn--solid" onClick={() => showToast(`Order placed for ${data.name}`)}>
                Order
              </button>
              <button type="button" className="btn btn--outline" onClick={() => showToast('Appointment request sent')}>
                Book Appointment
              </button>
            </div>
          </div>
        </div>

        <section className="detail-related" aria-label="You might also like">
          <h3 className="section-heading">You might also like</h3>
          <div className="related-grid">
            {related.map((m) => (
              <button type="button" className="related-card" key={m.name} onClick={() => onSelect?.(m)}>
                <div className="related-thumb">
                  <img src={m.image} alt={m.name} loading="lazy" />
                </div>
                <span className="related-name">{m.name}</span>
                <span className="related-price">{m.price}</span>
              </button>
            ))}
          </div>
        </section>
      </div>

      {toast && <div className="detail-toast">{toast}</div>}
    </div>
  );
}

/** Image carousel: large active image, prev/next arrows, and a thumbnail row. */
function Carousel({ images, alt }) {
  const [index, setIndex] = useState(0);

  // Clamp when the image set changes (switching products).
  useEffect(() => setIndex(0), [images]);

  const go = (next) => {
    setIndex((i) => (i + next + images.length) % images.length);
  };

  return (
    <div className="detail-gallery">
      <div className="gallery-main">
        <img src={images[index]} alt={alt} />
        {images.length > 1 && (
          <>
            <button type="button" className="gallery-arrow gallery-arrow--left" aria-label="Previous image" onClick={() => go(-1)}>
              ‹
            </button>
            <button type="button" className="gallery-arrow gallery-arrow--right" aria-label="Next image" onClick={() => go(1)}>
              ›
            </button>
          </>
        )}
      </div>

      {images.length > 1 && (
        <div className="gallery-thumbs">
          {images.map((src, i) => (
            <button
              type="button"
              key={src + i}
              className={`gallery-thumb${i === index ? ' gallery-thumb--active' : ''}`}
              onClick={() => setIndex(i)}
              aria-label={`View image ${i + 1}`}
            >
              <img src={src} alt="" loading="lazy" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ArrowLeft() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M19 12H5M12 19l-7-7 7-7" />
    </svg>
  );
}
function Bag() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4H6zM3.8 6 6 3h12l2.2 3H3.8z" />
    </svg>
  );
}
