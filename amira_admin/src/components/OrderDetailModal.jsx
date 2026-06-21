import Modal from './Modal.jsx';
import StatusBadge from './StatusBadge.jsx';
import { formatDateTime, updateDocById } from '../db.js';
import { money, titleCase } from '../utils.js';

const ORDER_STATUSES = [
  'pending', 'processing', 'paid', 'shipped', 'delivered', 'cancelled',
];

function lineTotal(item) {
  return (Number(item.value) || 0) * (Number(item.qty) || 0);
}

export default function OrderDetailModal({ order, onClose }) {
  if (!order) return null;

  const items = Array.isArray(order.items) ? order.items : [];
  const subtotal = items.reduce((s, i) => s + lineTotal(i), 0);
  const delivery = Math.max(0, (Number(order.total) || 0) - subtotal);

  const handleStatusChange = async (e) => {
    const status = e.target.value;
    if (status === order.status) return;
    await updateDocById('orders', order.id, { status });
  };

  return (
    <Modal
      title={order.orderId || order.id}
      onClose={onClose}
      footer={(
        <button type="button" className="ghost-btn" onClick={onClose}>
          Close
        </button>
      )}
    >
      <div className="order-detail">
        <div className="order-detail-head">
          <StatusBadge status={order.status} />
          <span className="cell-muted">{formatDateTime(order.createdAt)}</span>
        </div>

        <section className="order-detail-section">
          <h3 className="order-detail-label">Customer</h3>
          <p className="order-detail-strong">{order.customer || '—'}</p>
          <p className="cell-muted">{order.email || '—'}</p>
          {order.uid && (
            <p className="cell-sub" style={{ marginTop: 6 }}>uid: {order.uid}</p>
          )}
        </section>

        <section className="order-detail-section">
          <h3 className="order-detail-label">Delivery location</h3>
          <p className="order-detail-strong">{order.deliveryAddress || '—'}</p>
          {(order.deliveryCountry || order.deliveryLatitude != null) && (
            <p className="cell-muted">
              {order.deliveryCountry ? order.deliveryCountry : ''}
              {order.deliveryLatitude != null && order.deliveryLongitude != null && (
                <>
                  {order.deliveryCountry ? ' · ' : ''}
                  {Number(order.deliveryLatitude).toFixed(5)}, {Number(order.deliveryLongitude).toFixed(5)}
                </>
              )}
            </p>
          )}
        </section>

        <section className="order-detail-section">
          <h3 className="order-detail-label">Status</h3>
          <select
            className="order-detail-select"
            value={order.status || 'pending'}
            onChange={handleStatusChange}
          >
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>{titleCase(s)}</option>
            ))}
          </select>
        </section>

        <section className="order-detail-section">
          <h3 className="order-detail-label">Items ({order.itemCount ?? items.length})</h3>
          <ul className="order-lines">
            {items.map((item, i) => (
              <li key={`${item.productId}-${i}`} className="order-line">
                <div className="order-line-main">
                  <span className="order-line-name">{item.name || 'Product'}</span>
                  {item.colorName && (
                    <span className="order-line-color">
                      {item.colorHex && (
                        <span
                          className="order-color-dot"
                          style={{ background: item.colorHex }}
                          aria-hidden="true"
                        />
                      )}
                      {item.colorName}
                    </span>
                  )}
                  <span className="cell-muted">
                    {item.qty} × {money(item.value)}
                    {item.unit ? ` / ${item.unit}` : ''}
                  </span>
                </div>
                <span className="order-line-total serif-num">{money(lineTotal(item))}</span>
              </li>
            ))}
            {items.length === 0 && (
              <li className="cell-muted">No line items recorded.</li>
            )}
          </ul>
        </section>

        <section className="order-detail-totals">
          <div className="order-total-row">
            <span>Subtotal</span>
            <span className="serif-num">{money(subtotal)}</span>
          </div>
          {delivery > 0 && (
            <div className="order-total-row cell-muted">
              <span>Delivery</span>
              <span className="serif-num">{money(delivery)}</span>
            </div>
          )}
          <div className="order-total-row order-total-row--grand">
            <span>Total</span>
            <span className="serif-num">{money(order.total)}</span>
          </div>
        </section>

        {order.source && (
          <p className="cell-sub" style={{ marginTop: 16 }}>
            Source: {order.source}
          </p>
        )}
      </div>
    </Modal>
  );
}
