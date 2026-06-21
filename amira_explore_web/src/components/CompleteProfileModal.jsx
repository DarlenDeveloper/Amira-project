import { useState } from 'react';
import { updateProfile } from '../services/auth.js';
import { detectCountryIso, formatPhone } from '../lib/countries.js';
import PhoneField from './PhoneField.jsx';
import AddressField from './AddressField.jsx';

// Shown after Google sign-in (or on return visits) when phone is still missing.
export default function CompleteProfileModal({ onComplete, userName }) {
  const [countryIso, setCountryIso] = useState(() => detectCountryIso());
  const [phoneLocal, setPhoneLocal] = useState('');
  const [address, setAddress] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    const phone = formatPhone(countryIso, phoneLocal);
    if (phone.length < 8) {
      setError('Enter a valid phone number.');
      return;
    }
    setBusy(true);
    try {
      await updateProfile({
        phone,
        ...(address.trim() ? { address: address.trim() } : {}),
      });
      onComplete?.();
    } catch {
      setError('Could not save your details. Please try again.');
      setBusy(false);
    }
  };

  return (
    <div className="auth-overlay" role="dialog" aria-modal="true" aria-label="Complete your profile">
      <div className="auth-card">
        <span className="auth-brand">AMIRA</span>
        <h2 className="auth-title">Almost there{userName ? `, ${userName.split(' ')[0]}` : ''}</h2>
        <p className="auth-reason">
          Add your phone number so we can reach you about orders and deliveries.
        </p>

        <form className="auth-form" onSubmit={submit}>
          <div className="auth-field">
            <span>Phone number</span>
            <PhoneField
              countryIso={countryIso}
              nationalNumber={phoneLocal}
              onCountryChange={setCountryIso}
              onNumberChange={setPhoneLocal}
              disabled={busy}
              id="complete-phone"
            />
          </div>

          <div className="auth-field">
            <span>Delivery address</span>
            <AddressField
              value={address}
              onChange={setAddress}
              onCountryDetected={setCountryIso}
              disabled={busy}
              autoDetectOnMount
              id="complete-address"
            />
          </div>

          {error && <p className="auth-error">{error}</p>}

          <button type="submit" className="auth-submit" disabled={busy}>
            {busy ? 'Saving…' : 'Continue'}
          </button>
        </form>
      </div>
    </div>
  );
}
