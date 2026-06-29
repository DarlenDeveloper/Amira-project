import { useState, useEffect, useMemo } from 'react';
import { useShop } from '../context/ShopContext.jsx';
import { formatUgx } from '../lib/currency.js';
import { placeOrderForProduct } from '../services/orders.js';
import { requestAppointment } from '../services/appointments.js';
import DeliveryLocationField from './DeliveryLocationField.jsx';

// Web product page: image carousel (left) + specs & actions (right), then a
// "You might also like" row. Add-to-cart, order, and booking all hit the live
// backend; ordering/booking require a full account (handled via onRequireAccount).
export default function ProductDetail({ data, related = [], onClose, onSelect, onOpenCart, onRequireAccount }) {
  const { addToCart, hasAccount, user } = useShop();
  const [qty, setQty] = useState(1);
  const [toast, setToast] = useState(null);
  const [busy, setBusy] = useState(false);
  const [address, setAddress] = useState('');
  const [locationMeta, setLocationMeta] = useState({});

  const total = (data.value ?? 0) * qty;
  const soldOut = data.outOfStock;
  const hasColors = data.colors?.length > 0;
  const [selectedColor, setSelectedColor] = useState(null);

  const gallery = useMemo(
    () => (data.images?.length ? data.images : [data.image]),
    [data],
  );

  const relatedItems = useMemo(() => {
    // Candidates: everything except the current product and out-of-stock items.
    const pool = related.filter((m) => m.id !== data.id && !m.outOfStock);

    // Lightweight shuffle so the row isn't identical on every visit.
    const shuffle = (arr) => {
      const a = [...arr];
      for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
      }
      return a;
    };

    // Prefer same-category items, then fill remaining slots with others.
    const sameCategory = shuffle(pool.filter((m) => m.category && m.category === data.category));
    const others = shuffle(pool.filter((m) => m.category !== data.category));
    return [...sameCategory, ...others].slice(0, 4);
    // data.id pins the memo to the current product; reshuffles on navigation.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [related, data.id, data.category]);

  useEffect(() => {
    setQty(1);
    setSelectedColor(data.colors?.[0] ?? null);
    setAddress('');
    setLocationMeta({});
    document.querySelector('.detail-scroll')?.scrollTo({ top: 0 });
  }, [data]);

  const showToast = (msg) => {
    setToast(msg);
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => setToast(null), 1800);
  };

  const handleAddToCart = async () => {
    if (soldOut || busy) return;
    if (hasColors && !selectedColor) {
      showToast('Please select a colour');
      return;
    }
    setBusy(true);
    try {
      await addToCart(data, qty, selectedColor);
      const colorNote = selectedColor ? ` (${selectedColor.name})` : '';
      showToast(`${data.name}${colorNote} added to cart`);
    } catch {
      showToast('Could not add to cart. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  const runWhenAccount = (reason, action) => {
    if (hasAccount) return action();
    onRequireAccount?.(reason, action);
  };

  const handleOrder = () => {
    if (soldOut) return;
    const orderQty = qty;
    runWhenAccount('Sign in or create an account to place your order.', async () => {
      if (hasColors && !selectedColor) {
        showToast('Please select a colour');
        return;
      }
      setBusy(true);
      try {
        if (!address.trim()) {
          showToast('Enter your delivery location');
          return;
        }
        await placeOrderForProduct(data, orderQty, selectedColor, {
          address,
          ...locationMeta,
        });
        showToast(`Order placed for ${data.name}`);
      } catch (err) {
        console.error('[Amira] Order failed:', err?.code, err?.message);
        showToast('We couldn\'t place your order. Please try again.');
      } finally {
        setBusy(false);
      }
    });
  };

  const handleBook = () => {
    runWhenAccount('Sign in or create an account to book an appointment.', async () => {
      setBusy(true);
      try {
        await requestAppointment({ aboutProduct: data });
        showToast('Appointment request sent');
      } catch (err) {
        console.error('[Amira] Appointment request failed:', err?.code, err?.message);
        showToast('We couldn\'t send the request. Please try again.');
      } finally {
        setBusy(false);
      }
    });
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
            aria-label="Open cart"
            onClick={onOpenCart}
          >
            <Bag />
          </button>
        </div>

        <div className="detail-main">
          <Carousel images={gallery} alt={data.name} />

          <div className="detail-info">
            <div className="info-badges">
              {data.badge && <span className="info-badge">{data.badge}</span>}
              {soldOut && <span className="info-badge info-badge--out">Sold out</span>}
            </div>
            <h2 className="info-name">{data.name}</h2>
            <p className="info-price">
              {formatUgx(data.value)} <span className="info-unit">/ {data.unit}</span>
            </p>

            {data.about && <p className="info-about">{data.about}</p>}

            {hasColors && (
              <div className="color-block">
                <h3 className="color-title">Colour</h3>
                <div className="color-swatches" role="listbox" aria-label="Select colour">
                  {data.colors.map((c) => {
                    const active = selectedColor?.name === c.name;
                    return (
                      <button
                        type="button"
                        key={c.name}
                        role="option"
                        aria-selected={active}
                        className={`color-swatch${active ? ' color-swatch--active' : ''}`}
                        onClick={() => setSelectedColor(c)}
                        title={c.name}
                      >
                        <span className="color-swatch-dot" style={{ background: c.hex }} />
                        <span className="color-swatch-name">{c.name}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

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
                  <button type="button" className="qty-btn" aria-label="Decrease" onClick={() => setQty((q) => (q > 1 ? q - 1 : q))}>−</button>
                  <span className="qty-value">{qty}</span>
                  <button type="button" className="qty-btn" aria-label="Increase" onClick={() => setQty((q) => q + 1)}>+</button>
                </div>
              </div>
              <div className="info-total">
                <span className="info-total-label">Total</span>
                <span className="info-total-value">{formatUgx(total)}</span>
              </div>
            </div>

            {hasAccount && (
              <DeliveryLocationField
                user={user}
                hasAccount={hasAccount}
                address={address}
                onAddressChange={setAddress}
                onLocated={setLocationMeta}
                disabled={busy || soldOut}
                id="product-delivery-address"
              />
            )}

            <div className="info-actions">
              <button type="button" className="btn btn--solid" onClick={handleAddToCart} disabled={soldOut || busy}>
                {soldOut ? 'Sold out' : 'Add to cart'}
              </button>
              <button type="button" className="btn btn--outline" onClick={handleOrder} disabled={soldOut || busy}>
                Order now
              </button>
            </div>
            <button type="button" className="btn-link" onClick={handleBook} disabled={busy}>
              Book a consultation about this
            </button>
          </div>
        </div>

        {relatedItems.length > 0 && (
          <section className="detail-related" aria-label="You might also like">
            <h3 className="section-heading">You might also like</h3>
            <div className="related-grid">
              {relatedItems.map((m) => (
                <button type="button" className="related-card" key={m.id} onClick={() => onSelect?.(m)}>
                  <div className="related-thumb">
                    <img src={m.image} alt={m.name} loading="lazy" />
                  </div>
                  <span className="related-name">{m.name}</span>
                  <span className="related-price">{m.price}</span>
                </button>
              ))}
            </div>
          </section>
        )}
      </div>

      {toast && <div className="detail-toast">{toast}</div>}
    </div>
  );
}

/** Image carousel: large active image, prev/next arrows, and a thumbnail row. */
function Carousel({ images, alt }) {
  const [index, setIndex] = useState(0);

  useEffect(() => setIndex(0), [images]);

  const go = (next) => setIndex((i) => (i + next + images.length) % images.length);

  return (
    <div className="detail-gallery">
      <div className="gallery-main">
        <img src={images[index]} alt={alt} />
        {images.length > 1 && (
          <>
            <button type="button" className="gallery-arrow gallery-arrow--left" aria-label="Previous image" onClick={() => go(-1)}>‹</button>
            <button type="button" className="gallery-arrow gallery-arrow--right" aria-label="Next image" onClick={() => go(1)}>›</button>
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
