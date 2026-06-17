import { createContext, useContext, useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { auth } from './firebase.js';

// Real Firebase admin auth. Access is gated by the `admin: true` custom claim
// (set via tool/seed/set_admin.mjs). A signed-in user without the claim is
// rejected and signed out — only admins reach the dashboard.
const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (fbUser) => {
      if (!fbUser) {
        setUser(null);
        setLoading(false);
        return;
      }
      // Confirm the admin claim before granting access.
      const token = await fbUser.getIdTokenResult();
      if (token.claims.admin === true) {
        setUser({ uid: fbUser.uid, email: fbUser.email });
      } else {
        await signOut(auth);
        setUser(null);
      }
      setLoading(false);
    });
    return unsub;
  }, []);

  // Throws on failure (bad credentials) or 'not-admin' for non-admin accounts.
  const login = async (email, password) => {
    const cred = await signInWithEmailAndPassword(auth, email, password);
    const token = await cred.user.getIdTokenResult();
    if (token.claims.admin !== true) {
      await signOut(auth);
      const err = new Error('This account is not an admin.');
      err.code = 'not-admin';
      throw err;
    }
  };

  const logout = () => signOut(auth);

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);

/** Maps a Firebase auth error to a short admin-facing message. */
export function authMessage(err) {
  switch (err?.code) {
    case 'not-admin':
      return 'This account does not have admin access.';
    case 'auth/invalid-email':
      return 'Enter a valid email address.';
    case 'auth/missing-password':
      return 'Enter your password.';
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'Those details don\'t match our records.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Please wait and try again.';
    case 'auth/network-request-failed':
      return 'Network issue. Check your connection.';
    default:
      return err?.message ?? 'Something went wrong. Please try again.';
  }
}
