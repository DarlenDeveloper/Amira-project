import { useState } from 'react';
import { useShop } from '../context/ShopContext.jsx';
import { formatUgx } from '../lib/currency.js';
import { placeOrderFromCart, DELIVERY_FEE } from '../services/orders.js';

// Slide-in cart: live lines with quantity steppers, totals, and checkout.
// Checkout requires a full account — when the shopper is still anonymous it
// asks for one via `onRequireAccount`, then resumes automatically.
export default function CartDrawer({ onClose, onRequireAccount }) {
  const { cart, cartSubtotal, hasAccount, setQty, removeFromCart, clearCart } = useShop();
  const [placing, setPlacing] = useState(false);
  const [done, setDone] = useState(null); // placed order ref
  const [error, setError] = useState('');

  const isEmpty = cart.length === 0;
  const total = cartSubtotal + (isEmpty ? 0 : DELIVERY_FEE);

  const doCheckout = async () => {
    setPlacing(true);
    setError('');
    try {
      await placeOrderFromCart(cart);
      await clearCart();
      setDone(true);
    } catch (err) {
      console.error('[Amira] Checkout failed:', err?.code, err?.message);
      setError('We couldn\'t place your order. Please try again.');
    } finally {
      setPlacing(false);
    }
  };

  const checkout = () => {
    if (isEmpty) return;
    if (!hasAccount) {
      onRequireAccount('Sign in or create an account to place your order.', doCheckout);
      return;
    }
    doCheckout();
  };

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <aside
        className="cart-drawer"
        role="dialog"
        aria-modal="true"
        aria-label="Your cart"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="cart-head">
          <h2 className="cart-heading">Your cart</h2>
          <button type="button" className="circle-btn" aria-label="Close cart" onClick={onClose}>
            ×
          </button>
        </header>

        {done ? (
          <div className="cart-success">
            <div className="cart-success-mark">✓</div>
            <h3>Order placed</h3>
            <p>Thank you — we&apos;ve received your order and will be in touch shortly.</p>
            <button type="button" className="btn btn--solid" onClick={onClose}>
              Continue browsing
            </button>
          </div>
        ) : isEmpty ? (
          <div className="cart-empty">
            <p>Your cart is empty.</p>
            <button type="button" className="btn btn--outline" onClick={onClose}>
              Browse the collection
            </button>
          </div>
        ) : (
          <>
            <ul className="cart-lines">
              {cart.map((line) => (
                <li className="cart-line" key={line.productId}>
                  <div className="cart-line-thumb">
                    {line.imageUrl ? <img src={line.imageUrl} alt={line.name} /> : <div className="cart-line-ph" />}
                  </div>
                  <div className="cart-line-body">
                    <div className="cart-line-top">
                      <span className="cart-line-name">{line.name}</span>
                      <button
                        type="button"
                        className="cart-line-remove"
                        aria-label={`Remove ${line.name}`}
                        onClick={() => removeFromCart(line.productId)}
                      >
                        Remove
                      </button>
                    </div>
                    <span className="cart-line-unit">{formatUgx(line.value)} / {line.unit}</span>
                    <div className="cart-line-bottom">
                      <div className="qty-stepper qty-stepper--sm">
                        <button type="button" className="qty-btn" aria-label="Decrease" onClick={() => setQty(line.productId, line.qty - 1)}>−</button>
                        <span className="qty-value">{line.qty}</span>
                        <button type="button" className="qty-btn" aria-label="Increase" onClick={() => setQty(line.productId, line.qty + 1)}>+</button>
                      </div>
                      <span className="cart-line-total">{formatUgx(line.value * line.qty)}</span>
                    </div>
                  </div>
                </li>
              ))}
            </ul>

            <footer className="cart-foot">
              <div className="cart-row">
                <span>Subtotal</span>
                <span>{formatUgx(cartSubtotal)}</span>
              </div>
              <div className="cart-row cart-row--muted">
                <span>Delivery</span>
                <span>{formatUgx(DELIVERY_FEE)}</span>
              </div>
              <div className="cart-row cart-row--total">
                <span>Total</span>
                <span>{formatUgx(total)}</span>
              </div>

              {error && <p className="cart-error">{error}</p>}

              <button type="button" className="btn btn--solid cart-checkout" onClick={checkout} disabled={placing}>
                {placing ? 'Placing order…' : 'Checkout'}
              </button>
              <button type="button" className="cart-clear" onClick={clearCart} disabled={placing}>
                Clear cart
              </button>
            </footer>
          </>
        )}
      </aside>
    </div>
  );
}
