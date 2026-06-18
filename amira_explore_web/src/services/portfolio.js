// Live read of the admin-authored `portfolio` showcase. Used for the hero
// carousel — published projects make far better full-bleed hero imagery than
// product close-ups, and they stay in sync with whatever the admin publishes.
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase.js';

/**
 * Subscribes to published portfolio entries that have an image, ordered by the
 * admin's `order`. Calls `onData(items)` with `{ id, imageUrl, title }`.
 * Filtering/sorting is done client-side to avoid a composite index.
 * Returns the unsubscribe function.
 */
export function watchPortfolioImages(onData) {
  return onSnapshot(
    collection(db, 'portfolio'),
    (snap) => {
      const items = snap.docs
        .map((d) => ({ id: d.id, ...d.data() }))
        .filter((p) => p.status === 'published' && p.imageUrl)
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
        .map((p) => ({ id: p.id, imageUrl: p.imageUrl, title: p.title || '' }));
      onData(items);
    },
    () => onData([]), // on error, fall back to the static hero
  );
}
