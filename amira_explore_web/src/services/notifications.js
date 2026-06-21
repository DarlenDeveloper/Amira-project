// Admin broadcast notifications — readable by everyone (including guests).
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { db } from '../firebase.js';

function matchesAudience(data, uid) {
  const audience = String(data.audience || 'all').trim().toLowerCase();
  if (audience === 'all' || audience === 'all users' || audience === 'all users & guests') {
    return true;
  }
  if (uid && audience === `user:${uid}`) return true;
  return false;
}

function mapNotification(id, data = {}) {
  return {
    id,
    type: data.type || 'collection',
    title: data.title || '',
    body: data.body || '',
    audience: data.audience || 'all',
    sentAt: data.sentAt?.toDate?.() ?? null,
  };
}

/** Live broadcast feed for the current visitor (guests see "all" audience). */
export function watchNotifications(uid, onData, onError) {
  const q = query(collection(db, 'notifications'), orderBy('sentAt', 'desc'));
  return onSnapshot(
    q,
    (snap) => {
      const list = snap.docs
        .map((d) => mapNotification(d.id, d.data()))
        .filter((n) => matchesAudience(n, uid));
      onData(list);
    },
    (err) => onError?.(err),
  );
}

/** Per-user read state (works for anonymous guests too). */
export function watchReadIds(uid, onData) {
  if (!uid) {
    onData(new Set());
    return () => {};
  }
  return onSnapshot(
    collection(db, 'users', uid, 'notificationState'),
    (snap) => {
      const ids = new Set(
        snap.docs.filter((d) => d.data().readAt).map((d) => d.id),
      );
      onData(ids);
    },
    () => onData(new Set()),
  );
}

export async function markNotificationRead(uid, notificationId) {
  if (!uid || !notificationId) return;
  await setDoc(
    doc(db, 'users', uid, 'notificationState', notificationId),
    { readAt: serverTimestamp() },
    { merge: true },
  );
}

export function formatTimeAgo(date) {
  if (!date) return '';
  const diff = Date.now() - date.getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? '' : 's'} ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} day${days === 1 ? '' : 's'} ago`;
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

export const TYPE_STYLE = {
  collection: { label: 'Collection', emoji: '📦' },
  offer: { label: 'Offer', emoji: '🏷️' },
  order: { label: 'Order', emoji: '✓' },
  design: { label: 'Design', emoji: '✨' },
};
