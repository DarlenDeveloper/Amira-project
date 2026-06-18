import { useState } from 'react';
import {
  signInWithEmail,
  signUpWithEmail,
  signInWithGoogle,
  authMessage,
} from '../services/auth.js';

// Sign-in / create-account sheet. Shown when a shopper needs a full account
// (e.g. at checkout). On success the anonymous session is upgraded in place, so
// the cart carries over, then `onSuccess` runs (e.g. continue to checkout).
export default function AuthModal({ reason, onClose, onSuccess }) {
  const [mode, setMode] = useState('signin'); // 'signin' | 'signup'
  const [form, setForm] = useState({ name: '', email: '', address: '', password: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));
  const isSignup = mode === 'signup';

  const finish = () => {
    setBusy(false);
    onSuccess?.();
    onClose();
  };

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      if (isSignup) {
        await signUpWithEmail({
          email: form.email.trim(),
          password: form.password,
          name: form.name.trim(),
          address: form.address.trim(),
        });
      } else {
        await signInWithEmail(form.email.trim(), form.password);
      }
      finish();
    } catch (err) {
      setError(authMessage(err));
      setBusy(false);
    }
  };

  const google = async () => {
    setError('');
    setBusy(true);
    try {
      await signInWithGoogle();
      finish();
    } catch (err) {
      setError(authMessage(err));
      setBusy(false);
    }
  };

  return (
    <div className="auth-overlay" role="dialog" aria-modal="true" aria-label="Sign in">
      <div className="auth-card">
        <button type="button" className="auth-close" aria-label="Close" onClick={onClose}>
          ×
        </button>

        <span className="auth-brand">AMIRA</span>
        <h2 className="auth-title">{isSignup ? 'Create your account' : 'Welcome back'}</h2>
        {reason && <p className="auth-reason">{reason}</p>}

        <button type="button" className="auth-google" onClick={google} disabled={busy}>
          <GoogleMark />
          Continue with Google
        </button>

        <div className="auth-divider"><span>or</span></div>

        <form className="auth-form" onSubmit={submit}>
          {isSignup && (
            <label className="auth-field">
              <span>Full name</span>
              <input value={form.name} onChange={set('name')} placeholder="Amira Nakato" autoComplete="name" />
            </label>
          )}

          <label className="auth-field">
            <span>Email</span>
            <input type="email" value={form.email} onChange={set('email')} placeholder="you@email.com" autoComplete="email" />
          </label>

          {isSignup && (
            <label className="auth-field">
              <span>Delivery address</span>
              <input value={form.address} onChange={set('address')} placeholder="Kampala, Uganda" autoComplete="street-address" />
            </label>
          )}

          <label className="auth-field">
            <span>Password</span>
            <input
              type="password"
              value={form.password}
              onChange={set('password')}
              placeholder="••••••••"
              autoComplete={isSignup ? 'new-password' : 'current-password'}
            />
          </label>

          {error && <p className="auth-error">{error}</p>}

          <button type="submit" className="auth-submit" disabled={busy}>
            {busy ? 'Please wait…' : isSignup ? 'Create account' : 'Sign in'}
          </button>
        </form>

        <p className="auth-switch">
          {isSignup ? 'Already have an account?' : 'New to Amira?'}{' '}
          <button
            type="button"
            className="auth-switch-btn"
            onClick={() => {
              setError('');
              setMode(isSignup ? 'signin' : 'signup');
            }}
          >
            {isSignup ? 'Sign in' : 'Create one'}
          </button>
        </p>
      </div>
    </div>
  );
}

function GoogleMark() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
      <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.62z" />
      <path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.8.54-1.84.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18z" />
      <path fill="#FBBC05" d="M3.97 10.72a5.41 5.41 0 0 1 0-3.44V4.95H.96a9 9 0 0 0 0 8.1l3.01-2.33z" />
      <path fill="#EA4335" d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58z" />
    </svg>
  );
}
