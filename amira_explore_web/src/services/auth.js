// Auth for the web shop.
//
// Model: visitors are signed in ANONYMOUSLY on load so they can read the live
// catalogue (the security rules require a signed-in user even to read products)
// and build a cart. A FULL account (email/password or Google) is required at
// checkout so orders attach to a retrievable account and the admin gets real
// customer details. On sign-up the anonymous account is UPGRADED in place, so
// the cart and favourites built while browsing carry over seamlessly.
import {
  signInAnonymously,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  EmailAuthProvider,
  GoogleAuthProvider,
  linkWithCredential,
  linkWithPopup,
  signInWithPopup,
  signInWithCredential,
  updateProfile as updateAuthProfile,
  signOut as fbSignOut,
} from 'firebase/auth';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { auth, db } from '../firebase.js';

const googleProvider = new GoogleAuthProvider();

/** True once the user has a real (non-anonymous) account. */
export function isFullAccount(user) {
  return Boolean(user && !user.isAnonymous);
}

/**
 * Subscribes to auth state. If nobody is signed in, signs in anonymously so the
 * catalogue is readable. Calls `onUser(user)` with the resolved user.
 * Returns the unsubscribe function.
 */
export function watchAuth(onUser) {
  return onAuthStateChanged(auth, async (user) => {
    if (!user) {
      try {
        await signInAnonymously(auth);
        return; // listener fires again with the anonymous user
      } catch (err) {
        // Most common cause: the Anonymous sign-in provider isn't enabled in
        // the Firebase console (Authentication → Sign-in method).
        console.error('[Amira] Anonymous sign-in failed:', err?.code, err?.message);
        onUser(null, err);
        return;
      }
    }
    onUser(user);
  });
}

// ── Profile (Firestore users/{uid}) ─────────────────────────────────────────
// Writes only the fields the security rules permit. Never overwrites with nulls.
async function upsertProfile(user, { name, email, phone, address, photoUrl, isNew } = {}) {
  const data = { updatedAt: serverTimestamp() };
  if (name) data.name = name;
  if (email) data.email = email;
  if (phone) data.phone = phone;
  if (address) data.address = address;
  if (photoUrl) data.photoUrl = photoUrl;
  if (isNew) data.createdAt = serverTimestamp();
  await setDoc(doc(db, 'users', user.uid), data, { merge: true });
}

// ── Email / password ─────────────────────────────────────────────────────────
export async function signInWithEmail(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  await upsertProfile(cred.user, { email });
  return cred.user;
}

/**
 * Creates a full account. If the current session is anonymous, the new email
 * credential is LINKED to it so the same uid (and its cart) is kept. Falls back
 * to a plain sign-up if there's no anonymous session to upgrade.
 */
export async function signUpWithEmail({ email, password, name, address }) {
  const current = auth.currentUser;
  let user;
  if (current?.isAnonymous) {
    const credential = EmailAuthProvider.credential(email, password);
    const result = await linkWithCredential(current, credential);
    user = result.user;
  } else {
    const result = await createUserWithEmailAndPassword(auth, email, password);
    user = result.user;
  }
  if (name) await updateAuthProfile(user, { displayName: name });
  await upsertProfile(user, { name, email, address, isNew: true });
  return user;
}

// ── Google ─────────────────────────────────────────────────────────────────
/**
 * Signs in with Google. Upgrades an anonymous session in place when possible;
 * if the Google account already exists, falls back to a normal sign-in.
 */
export async function signInWithGoogle() {
  const current = auth.currentUser;
  let user;
  try {
    if (current?.isAnonymous) {
      const result = await linkWithPopup(current, googleProvider);
      user = result.user;
    } else {
      const result = await signInWithPopup(auth, googleProvider);
      user = result.user;
    }
  } catch (err) {
    // The Google account is already linked to another user — sign into it
    // directly (the anonymous cart can't be merged in this edge case).
    if (err?.code === 'auth/credential-already-in-use') {
      const credential = GoogleAuthProvider.credentialFromError(err);
      const result = await signInWithCredential(auth, credential);
      user = result.user;
    } else {
      throw err;
    }
  }
  await upsertProfile(user, {
    name: user.displayName,
    email: user.email,
    photoUrl: user.photoURL,
    isNew: true,
  });
  return user;
}

// ── Session ──────────────────────────────────────────────────────────────────
/** Signs out and immediately drops back to an anonymous browsing session. */
export async function signOut() {
  await fbSignOut(auth);
  await signInAnonymously(auth);
}

/** Maps a Firebase auth error code to a short, warm, shopper-facing message. */
export function authMessage(err) {
  switch (err?.code) {
    case 'auth/invalid-email':
      return 'That email address doesn\'t look right.';
    case 'auth/missing-password':
      return 'Enter your password.';
    case 'auth/weak-password':
      return 'Please choose a stronger password (at least 6 characters).';
    case 'auth/email-already-in-use':
      return 'An account already exists for that email. Try signing in.';
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'Those details don\'t match our records.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return 'Sign-in was cancelled.';
    case 'auth/network-request-failed':
      return 'Network issue. Please check your connection.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
