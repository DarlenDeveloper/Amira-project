// Password reset via email OTP (Cloud Functions) or phone SMS OTP (Firebase Auth).
import { httpsCallable } from 'firebase/functions';
import {
  RecaptchaVerifier,
  signInWithPhoneNumber,
  signInAnonymously,
  signOut as fbSignOut,
} from 'firebase/auth';
import { auth, functions } from '../firebase.js';

export function passwordResetMessage(err) {
  const code = err?.code || '';
  const msg = err?.message || '';
  if (code.includes('invalid-argument')) return msg || 'Check the details you entered.';
  if (code.includes('deadline-exceeded')) return 'That code has expired. Request a new one.';
  if (code.includes('not-found')) return 'That code has expired. Request a new one.';
  if (code.includes('resource-exhausted')) return 'Too many attempts. Request a new code.';
  if (code.includes('failed-precondition')) return msg || 'Try resetting with your phone instead.';
  if (code === 'auth/invalid-verification-code') return 'That SMS code is incorrect.';
  if (code === 'auth/code-expired') return 'That SMS code has expired. Request a new one.';
  if (code === 'auth/too-many-requests') return 'Too many attempts. Please wait and try again.';
  if (code === 'auth/invalid-phone-number') return 'That phone number doesn\'t look right.';
  return msg || 'Something went wrong. Please try again.';
}

/** Email a 6-digit OTP to the account holder. */
export async function requestEmailPasswordOtp(email) {
  const fn = httpsCallable(functions, 'requestPasswordResetOtp');
  const { data } = await fn({ email: email.trim().toLowerCase() });
  return data;
}

/** Verify email OTP and set a new password. */
export async function resetPasswordWithEmailOtp({ email, code, newPassword }) {
  const fn = httpsCallable(functions, 'resetPasswordWithOtp');
  const { data } = await fn({
    email: email.trim().toLowerCase(),
    code: code.trim(),
    newPassword,
  });
  return data;
}

let recaptchaVerifier = null;

function getRecaptcha(containerId) {
  if (recaptchaVerifier) {
    try {
      recaptchaVerifier.clear();
    } catch {
      // ignore
    }
    recaptchaVerifier = null;
  }
  recaptchaVerifier = new RecaptchaVerifier(auth, containerId, {
    size: 'invisible',
  });
  return recaptchaVerifier;
}

/** Send Firebase SMS OTP to the given E.164 phone number. */
export async function sendPhonePasswordOtp(phoneE164, containerId = 'recaptcha-container') {
  const verifier = getRecaptcha(containerId);
  return signInWithPhoneNumber(auth, phoneE164, verifier);
}

/** Confirm SMS OTP, set new password via Cloud Function, return to anonymous browse. */
export async function resetPasswordWithPhoneOtp({ confirmationResult, code, newPassword }) {
  await confirmationResult.confirm(code);
  const fn = httpsCallable(functions, 'resetPasswordAfterPhoneVerification');
  await fn({ newPassword });
  await fbSignOut(auth);
  await signInAnonymously(auth);
}
