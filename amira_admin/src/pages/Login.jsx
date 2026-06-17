import { useState } from 'react';
import { useAuth, authMessage } from '../auth.jsx';

export default function Login() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    if (!email.includes('@')) {
      setError('Enter a valid email address.');
      return;
    }
    if (password.length < 4) {
      setError('Enter your password.');
      return;
    }
    setError('');
    setBusy(true);
    try {
      await login(email.trim(), password);
      // On success, AuthProvider flips the app to the dashboard.
    } catch (err) {
      setError(authMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="login">
      <div className="login-brand">
        <span className="login-name">AMIRA</span>
        <span className="login-sub">ATELIER · ADMIN</span>
      </div>

      <form className="login-card" onSubmit={submit}>
        <p className="login-eyebrow">Welcome back</p>
        <h1 className="login-title">Sign in</h1>

        <label className="login-field">
          <span>Email</span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@amira.com"
            autoComplete="username"
          />
        </label>

        <label className="login-field">
          <span>Password</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
          />
        </label>

        {error && <p className="login-error">{error}</p>}

        <button type="submit" className="login-btn" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign in'}
        </button>

        <p className="login-note">Admin access only.</p>
      </form>
    </div>
  );
}
