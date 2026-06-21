import { useEffect, useState } from 'react';
import { detectCountryIso, formatPhone } from '../lib/countries.js';
import PhoneField from './PhoneField.jsx';
import {
  requestEmailPasswordOtp,
  resetPasswordWithEmailOtp,
  sendPhonePasswordOtp,
  resetPasswordWithPhoneOtp,
  passwordResetMessage,
} from '../services/passwordReset.js';

// Forgot password: email OTP (6-digit code) or phone SMS OTP, then set a new password.
export default function ForgotPasswordModal({ onBack, onDone }) {
  const [channel, setChannel] = useState('email'); // 'email' | 'phone'
  const [step, setStep] = useState('identify'); // identify | otp | password | done
  const [email, setEmail] = useState('');
  const [countryIso, setCountryIso] = useState(() => detectCountryIso());
  const [phoneLocal, setPhoneLocal] = useState('');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [phoneConfirmation, setPhoneConfirmation] = useState(null);

  useEffect(() => {
    setCountryIso(detectCountryIso());
  }, [channel]);

  const resetErrors = () => {
    setError('');
    setInfo('');
  };

  const sendEmailOtp = async (e) => {
    e?.preventDefault();
    resetErrors();
    if (!email.trim()) {
      setError('Enter the email on your account.');
      return;
    }
    setBusy(true);
    try {
      const result = await requestEmailPasswordOtp(email);
      if (result?.devOtp) {
        setInfo(`Dev mode: your code is ${result.devOtp}`);
      } else {
        setInfo('We sent a 6-digit code to your email.');
      }
      setStep('otp');
    } catch (err) {
      setError(passwordResetMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const sendPhoneOtp = async (e) => {
    e?.preventDefault();
    resetErrors();
    const phoneE164 = formatPhone(countryIso, phoneLocal);
    if (phoneE164.length < 8) {
      setError('Enter a valid phone number.');
      return;
    }
    setBusy(true);
    try {
      const confirmation = await sendPhonePasswordOtp(phoneE164);
      setPhoneConfirmation(confirmation);
      setInfo('We sent a 6-digit SMS code to your phone.');
      setStep('otp');
    } catch (err) {
      setError(passwordResetMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const verifyOtp = async (e) => {
    e.preventDefault();
    resetErrors();
    if (otp.trim().length !== 6) {
      setError('Enter the 6-digit code.');
      return;
    }
    if (channel === 'phone' && !phoneConfirmation) {
      setError('Request a new SMS code.');
      return;
    }
    setStep('password');
  };

  const setPassword = async (e) => {
    e.preventDefault();
    resetErrors();
    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }
    setBusy(true);
    try {
      if (channel === 'email') {
        await resetPasswordWithEmailOtp({
          email,
          code: otp,
          newPassword,
        });
      } else {
        await resetPasswordWithPhoneOtp({
          confirmationResult: phoneConfirmation,
          code: otp,
          newPassword,
        });
      }
      setStep('done');
    } catch (err) {
      setError(passwordResetMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="auth-overlay" role="dialog" aria-modal="true" aria-label="Reset password">
      <div className="auth-card auth-card--wide">
        <button type="button" className="auth-close" aria-label="Back" onClick={onBack}>
          ←
        </button>

        <span className="auth-brand">AMIRA</span>
        <h2 className="auth-title">
          {step === 'done' ? 'Password updated' : 'Reset password'}
        </h2>

        {step === 'done' ? (
          <div className="forgot-done">
            <p className="auth-reason">Your password has been changed. You can sign in with your new password.</p>
            <button type="button" className="auth-submit" onClick={onDone}>
              Back to sign in
            </button>
          </div>
        ) : (
          <>
            {step === 'identify' && (
              <div className="forgot-tabs" role="tablist" aria-label="Reset method">
                <button
                  type="button"
                  role="tab"
                  aria-selected={channel === 'email'}
                  className={`forgot-tab${channel === 'email' ? ' forgot-tab--active' : ''}`}
                  onClick={() => {
                    resetErrors();
                    setChannel('email');
                  }}
                >
                  Email OTP
                </button>
                <button
                  type="button"
                  role="tab"
                  aria-selected={channel === 'phone'}
                  className={`forgot-tab${channel === 'phone' ? ' forgot-tab--active' : ''}`}
                  onClick={() => {
                    resetErrors();
                    setChannel('phone');
                  }}
                >
                  Phone OTP
                </button>
              </div>
            )}

            {step === 'identify' && channel === 'email' && (
              <form className="auth-form" onSubmit={sendEmailOtp}>
                <p className="auth-reason">
                  Enter your account email. We&apos;ll send a 6-digit code to reset your password.
                </p>
                <label className="auth-field">
                  <span>Email</span>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@email.com"
                    autoComplete="email"
                    required
                  />
                </label>
                {error && <p className="auth-error">{error}</p>}
                {info && <p className="auth-info">{info}</p>}
                <button type="submit" className="auth-submit" disabled={busy}>
                  {busy ? 'Sending…' : 'Send code'}
                </button>
              </form>
            )}

            {step === 'identify' && channel === 'phone' && (
              <form className="auth-form" onSubmit={sendPhoneOtp}>
                <p className="auth-reason">
                  Enter the phone number on your account. We&apos;ll text you a 6-digit code.
                </p>
                <div className="auth-field">
                  <span>Phone number</span>
                  <PhoneField
                    countryIso={countryIso}
                    nationalNumber={phoneLocal}
                    onCountryChange={setCountryIso}
                    onNumberChange={setPhoneLocal}
                    disabled={busy}
                    id="forgot-phone"
                  />
                </div>
                <div id="recaptcha-container" />
                {error && <p className="auth-error">{error}</p>}
                {info && <p className="auth-info">{info}</p>}
                <button type="submit" className="auth-submit" disabled={busy}>
                  {busy ? 'Sending…' : 'Send SMS code'}
                </button>
              </form>
            )}

            {step === 'otp' && (
              <form className="auth-form" onSubmit={verifyOtp}>
                <p className="auth-reason">{info || 'Enter the 6-digit code we sent you.'}</p>
                <label className="auth-field">
                  <span>Verification code</span>
                  <input
                    className="otp-input"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    maxLength={6}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                    placeholder="000000"
                    required
                  />
                </label>
                {error && <p className="auth-error">{error}</p>}
                <button type="submit" className="auth-submit" disabled={busy}>
                  Continue
                </button>
                <button
                  type="button"
                  className="auth-switch-btn forgot-resend"
                  onClick={() => {
                    setOtp('');
                    setStep('identify');
                    resetErrors();
                  }}
                >
                  Request a new code
                </button>
              </form>
            )}

            {step === 'password' && (
              <form className="auth-form" onSubmit={setPassword}>
                <p className="auth-reason">Choose a new password for your account.</p>
                <label className="auth-field">
                  <span>New password</span>
                  <input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                </label>
                <label className="auth-field">
                  <span>Confirm password</span>
                  <input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    autoComplete="new-password"
                    required
                  />
                </label>
                {error && <p className="auth-error">{error}</p>}
                <button type="submit" className="auth-submit" disabled={busy}>
                  {busy ? 'Saving…' : 'Update password'}
                </button>
              </form>
            )}
          </>
        )}
      </div>
    </div>
  );
}
