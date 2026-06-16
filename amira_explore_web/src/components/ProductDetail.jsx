import { useState } from 'react';

// Full product view — mirrors the Flutter ItemDetailsScreen: hero image with
// back/cart, name + quantity stepper, price, description, and a sticky bottom
// bar with the slide-to-visualise action plus Order / Book Appointment.
export default function ProductDetail({ data, onClose }) {
  const [qty, setQty] = useState(1);
  const [toast, setToast] = useState(null);

  const total = (data.value ?? 0) * qty;

  const showToast = (msg) => {
    setToast(msg);
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => setToast(null), 1600);
  };

  return (
    <div className="detail" role="dialog" aria-modal="true" aria-label={data.name}>
      <div className="detail-scroll">
        <div className="detail-image-wrap">
          <img className="detail-image" src={data.image} alt={data.name} />
          <div className="detail-top-row">
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
        </div>

        <div className="detail-body">
          <div className="detail-name-row">
            <h2 className="detail-name">{data.name}</h2>
            <QtyStepper
              qty={qty}
              onInc={() => setQty((q) => q + 1)}
              onDec={() => setQty((q) => (q > 1 ? q - 1 : q))}
            />
          </div>

          <p className="detail-unit-price">
            ${data.value} / {data.unit}
          </p>

          <p className="detail-about">{data.about}</p>
        </div>
      </div>

      <div className="detail-bottom">
        <div className="detail-bottom-top">
          <div className="detail-total">
            <span className="detail-total-label">Total Price</span>
            <span className="detail-total-value">${total}</span>
          </div>
        </div>

        <div className="detail-actions">
          <button
            type="button"
            className="btn btn--solid"
            onClick={() => showToast(`Order placed for ${data.name}`)}
          >
            Order
          </button>
          <button
            type="button"
            className="btn btn--outline"
            onClick={() => showToast('Appointment request sent')}
          >
            Book Appointment
          </button>
        </div>
      </div>

      {toast && <div className="detail-toast">{toast}</div>}
    </div>
  );
}

function QtyStepper({ qty, onInc, onDec }) {
  return (
    <div className="qty-stepper">
      <button type="button" className="qty-btn" aria-label="Decrease" onClick={onDec}>
        −
      </button>
      <span className="qty-value">{qty}</span>
      <button type="button" className="qty-btn" aria-label="Increase" onClick={onInc}>
        +
      </button>
    </div>
  );
}

/** Drag the gold thumb to the right to trigger [onComplete]. */
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
