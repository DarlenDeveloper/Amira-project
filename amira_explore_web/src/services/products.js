// Live read access to the admin-authored `products` catalogue.
//
// Products are written by the admin dashboard and read here unchanged (same
// Firestore collection the Flutter app reads). Each doc is mapped to the shape
// the existing UI components expect (image, price label, specs, …).
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore';
import { db } from '../firebase.js';
import { priceLabel } from '../lib/currency.js';
import { normalizeColors } from '../lib/productColors.js';

const PLACEHOLDER = '/images/hero.jpg';

const STATUS_LABEL = {
  active: 'In stock',
  low: 'Low stock',
  out: 'Out of stock',
};

/**
 * Maps a Firestore product doc to the UI model used across the explore page.
 * Firestore products have no `specs` array, so a small spec list is derived
 * from the structured fields the admin does provide.
 */
export function mapProduct(id, data = {}) {
  const value = Number(data.value) || 0;
  const unit = data.unit || 'unit';
  const images = Array.isArray(data.images) && data.images.length
    ? data.images
    : data.imageUrl
      ? [data.imageUrl]
      : [];
  const status = data.status || 'active';

  const specs = [];
  if (data.category) specs.push({ label: 'Category', value: data.category });
  specs.push({ label: 'Sold by', value: unitLabel(unit) });
  if (STATUS_LABEL[status]) {
    specs.push({ label: 'Availability', value: STATUS_LABEL[status] });
  }

  return {
    id,
    name: data.name || 'Untitled',
    imageKey: data.imageKey || '',
    image: images[0] || PLACEHOLDER,
    images: images.length ? images : [PLACEHOLDER],
    imageUrl: data.imageUrl ?? images[0] ?? null,
    category: data.category || '',
    value,
    unit,
    price: priceLabel(value, unit),
    badge: data.badge || null,
    about: data.about || data.desc || '',
    desc: data.desc || '',
    stock: Number(data.stock) || 0,
    status,
    outOfStock: status === 'out' || (Number(data.stock) || 0) <= 0,
    order: Number(data.order) || 0,
    colors: normalizeColors(data.colors),
  };
}

function unitLabel(unit) {
  switch (unit) {
    case 'sqm': return 'Square metre';
    case 'm': return 'Metre';
    case 'sheet': return 'Sheet';
    default: return 'Unit';
  }
}

/**
 * Subscribes to the live catalogue, ordered the same way the app orders it.
 * Calls `onData(products)` on every change and `onError(err)` on failure.
 * Returns the unsubscribe function.
 */
export function watchProducts(onData, onError) {
  const q = query(collection(db, 'products'), orderBy('order'));
  return onSnapshot(
    q,
    (snap) => onData(snap.docs.map((d) => mapProduct(d.id, d.data()))),
    (err) => onError?.(err),
  );
}

/** Distinct category labels present in the catalogue, in first-seen order. */
export function categoriesOf(products) {
  const seen = new Set();
  const out = [];
  for (const p of products) {
    if (p.category && !seen.has(p.category)) {
      seen.add(p.category);
      out.push(p.category);
    }
  }
  return out;
}
