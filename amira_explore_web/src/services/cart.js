// Per-user cart + favourites, backed by `users/{uid}/…` — the exact same
// documents the Flutter app's ShopService uses, so a cart built on the web shows
// up in the app and vice-versa.
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  onSnapshot,
  runTransaction,
  serverTimestamp,
  setDoc,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../firebase.js';

const userDoc = (uid) => doc(db, 'users', uid);
const cartCol = (uid) => collection(userDoc(uid), 'cart');
const favCol = (uid) => collection(userDoc(uid), 'favourites');

// ── Cart ─────────────────────────────────────────────────────────────────────
// users/{uid}/cart/{productId} → { name, imageKey, imageUrl?, unit, value, qty }

function cartLineFromDoc(d) {
  const data = d.data() || {};
  return {
    productId: d.id,
    name: data.name || '',
    imageUrl: data.imageUrl || null,
    unit: data.unit || 'unit',
    value: Number(data.value) || 0,
    qty: Number(data.qty) || 1,
    get lineTotal() {
      return this.value * this.qty;
    },
  };
}

/** Live cart lines for a user. Returns the unsubscribe function. */
export function watchCart(uid, onData) {
  return onSnapshot(cartCol(uid), (snap) => {
    onData(snap.docs.map(cartLineFromDoc));
  });
}

/** Adds `qty` of a product, merging with any existing line (transactional). */
export async function addToCart(uid, product, qty = 1) {
  const ref = doc(cartCol(uid), product.id);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.exists() ? Number(snap.data().qty) || 0 : 0;
    tx.set(
      ref,
      {
        name: product.name,
        imageKey: product.imageKey ?? '',
        ...(product.imageUrl ? { imageUrl: product.imageUrl } : {}),
        unit: product.unit,
        value: product.value,
        qty: existing + qty,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  });
}

/** Sets an absolute quantity; removes the line when `qty` <= 0. */
export async function setQty(uid, productId, qty) {
  const ref = doc(cartCol(uid), productId);
  if (qty <= 0) {
    await deleteDoc(ref);
    return;
  }
  await setDoc(ref, { qty, updatedAt: serverTimestamp() }, { merge: true });
}

export function removeFromCart(uid, productId) {
  return deleteDoc(doc(cartCol(uid), productId));
}

export async function clearCart(uid) {
  const snap = await getDocs(cartCol(uid));
  const batch = writeBatch(db);
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

// ── Favourites ────────────────────────────────────────────────────────────────
// users/{uid}/favourites/{productId} → { addedAt }

/** Live set of favourited product ids. Returns the unsubscribe function. */
export function watchFavourites(uid, onData) {
  return onSnapshot(favCol(uid), (snap) => {
    onData(new Set(snap.docs.map((d) => d.id)));
  });
}

export function setFavourite(uid, productId, isFavourite) {
  const ref = doc(favCol(uid), productId);
  return isFavourite
    ? setDoc(ref, { addedAt: serverTimestamp() })
    : deleteDoc(ref);
}
