// Order creation + history, backed by the shared `orders` collection.
//
// Orders are written by the customer as `pending`; the admin advances the
// status. Field names and the delivery fee match the Flutter app's
// OrderService so both clients produce identical order documents.
import {
  addDoc,
  collection,
  getDoc,
  doc,
  onSnapshot,
  query,
  serverTimestamp,
  where,
} from 'firebase/firestore';
import { auth, db } from '../firebase.js';
import { baseProductId } from '../lib/productColors.js';

export const DELIVERY_FEE = 30;

const ordersCol = () => collection(db, 'orders');

function orderItem(line) {
  return {
    productId: baseProductId(line.productId),
    name: line.name,
    ...(line.imageUrl ? { imageUrl: line.imageUrl } : {}),
    unit: line.unit,
    value: line.value,
    qty: line.qty,
    ...(line.colorName ? { colorName: line.colorName, colorHex: line.colorHex } : {}),
  };
}

/** Human-friendly reference, e.g. "AM-04217". The doc id stays the true key. */
function newOrderRef() {
  const n = Date.now() % 100000;
  return `AM-${String(n).padStart(5, '0')}`;
}

async function resolveCustomer(user) {
  let profile = {};
  try {
    const snap = await getDoc(doc(db, 'users', user.uid));
    if (snap.exists()) profile = snap.data();
  } catch {
    // Best effort — fall back to auth fields below.
  }
  const customer =
    profile.name?.trim() || user.displayName?.trim() || 'Amira Member';
  const email = profile.email || profile.phone || user.email || '';
  return { customer, email };
}

/** Maps checkout location into order document fields. */
export function normalizeDeliveryLocation(location) {
  const address = String(location?.address || '').trim();
  if (!address) return null;
  const payload = { deliveryAddress: address };
  const lat = Number(location?.latitude);
  const lng = Number(location?.longitude);
  if (Number.isFinite(lat)) payload.deliveryLatitude = lat;
  if (Number.isFinite(lng)) payload.deliveryLongitude = lng;
  if (location?.countryIso) {
    payload.deliveryCountry = String(location.countryIso).toUpperCase();
  }
  return payload;
}

async function create(items, total, location) {
  const user = auth.currentUser;
  if (!user || user.isAnonymous) {
    const err = new Error('Sign in to place an order.');
    err.code = 'needs-account';
    throw err;
  }
  const delivery = normalizeDeliveryLocation(location);
  if (!delivery) {
    const err = new Error('A delivery address is required.');
    err.code = 'needs-location';
    throw err;
  }
  const { customer, email } = await resolveCustomer(user);
  await addDoc(ordersCol(), {
    orderId: newOrderRef(),
    uid: user.uid,
    customer,
    email,
    ...delivery,
    items,
    itemCount: items.reduce((s, i) => s + i.qty, 0),
    total,
    status: 'pending',
    source: 'web',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

/** Places an order for every cart line (adds delivery). Caller clears the cart. */
export async function placeOrderFromCart(lines, location) {
  if (!lines.length) return;
  const items = lines.map(orderItem);
  const subtotal = items.reduce((s, i) => s + i.value * i.qty, 0);
  await create(items, subtotal + DELIVERY_FEE, location);
}

/** Places an order for a single product at the chosen quantity (no delivery). */
export async function placeOrderForProduct(product, qty, color = null, location) {
  const item = orderItem({
    productId: product.id,
    name: product.name,
    imageUrl: product.imageUrl,
    unit: product.unit,
    value: product.value,
    qty,
    ...(color?.name ? { colorName: color.name, colorHex: color.hex } : {}),
  });
  await create([item], item.value * item.qty, location);
}

function orderFromDoc(d) {
  const data = d.data() || {};
  return {
    id: d.id,
    orderId: data.orderId || d.id,
    items: Array.isArray(data.items) ? data.items : [],
    total: Number(data.total) || 0,
    status: data.status || 'pending',
    itemCount: Number(data.itemCount) || 0,
    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : null,
  };
}

/** Live list of the signed-in user's orders, newest first. */
export function watchMyOrders(uid, onData) {
  const q = query(ordersCol(), where('uid', '==', uid));
  return onSnapshot(q, (snap) => {
    const orders = snap.docs.map(orderFromDoc);
    orders.sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
    onData(orders);
  });
}
