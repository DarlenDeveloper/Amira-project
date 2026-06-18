// Firestore profile for the signed-in user (users/{uid}).
import { doc, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase.js';

/** Live profile document for the current uid. */
export function watchProfile(uid, onData) {
  if (!uid) return () => {};
  return onSnapshot(
    doc(db, 'users', uid),
    (snap) => onData(snap.exists() ? snap.data() : null),
    (err) => {
      console.error('[Amira] Profile read failed:', err?.code, err?.message);
      onData(null);
    },
  );
}

/** Display name from Firestore profile + Firebase Auth user. */
export function displayName(user, profile) {
  return (
    profile?.name?.trim() ||
    user?.displayName?.trim() ||
    user?.email?.split('@')[0] ||
    'Member'
  );
}

/** Email or phone for display. */
export function displayEmail(user, profile) {
  return profile?.email || user?.email || profile?.phone || '';
}
