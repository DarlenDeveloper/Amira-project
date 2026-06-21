// Page and product visit events for the web shop (`pageViews` collection).
import { addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase.js';
import { isFullAccount } from './auth.js';

/**
 * Records a page or product view. Works for guests (anonymous auth) and members.
 * Fire-and-forget — failures are logged only.
 */
export async function trackPageView(user, { page, productId, productName, category } = {}) {
  if (!user?.uid || !page) return;
  try {
    await addDoc(collection(db, 'pageViews'), {
      uid: user.uid,
      isGuest: !isFullAccount(user),
      source: 'web',
      page: String(page),
      ...(productId ? { productId: String(productId) } : {}),
      ...(productName ? { productName: String(productName) } : {}),
      ...(category ? { category: String(category) } : {}),
      createdAt: serverTimestamp(),
    });
  } catch (err) {
    console.warn('[Amira] Analytics write failed:', err?.code, err?.message);
  }
}
