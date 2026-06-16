import { createContext, useContext, useState } from 'react';

// Lightweight front-end auth gate. Session is persisted in localStorage.
// NOTE: placeholder — to be replaced with real Firebase admin auth (with an
// admin-claim / allowlist check) when the backend is wired.
const AuthContext = createContext(null);
const SESSION_KEY = 'amira_admin_session';

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const raw = localStorage.getItem(SESSION_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  });

  const login = (email) => {
    const session = { email, since: Date.now() };
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
    setUser(session);
  };

  const logout = () => {
    localStorage.removeItem(SESSION_KEY);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
