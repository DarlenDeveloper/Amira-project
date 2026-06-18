// Appointment requests, backed by the shared `appointments` collection.
//
// Created by the customer as `requested`; the admin schedules it and advances
// the status. Field names match the Flutter app's AppointmentService so both
// clients produce identical documents.
import { addDoc, collection, getDoc, doc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../firebase.js';

function newRef() {
  const n = Date.now() % 10000;
  return `AP-${String(n).padStart(4, '0')}`;
}

async function resolveCustomer(user) {
  let profile = {};
  try {
    const snap = await getDoc(doc(db, 'users', user.uid));
    if (snap.exists()) profile = snap.data();
  } catch {
    // Best effort — fall back to auth fields.
  }
  const customer =
    profile.name?.trim() || user.displayName?.trim() || 'Amira Member';
  const email = profile.email || profile.phone || user.email || '';
  return { customer, email };
}

/**
 * Requests an appointment. Requires a full account (so the admin can follow up).
 * `aboutProduct` optionally records which product prompted the enquiry.
 */
export async function requestAppointment({ type = 'Design Consultation', aboutProduct } = {}) {
  const user = auth.currentUser;
  if (!user || user.isAnonymous) {
    const err = new Error('Sign in to book an appointment.');
    err.code = 'needs-account';
    throw err;
  }
  const { customer, email } = await resolveCustomer(user);
  await addDoc(collection(db, 'appointments'), {
    appointmentId: newRef(),
    uid: user.uid,
    customer,
    email,
    type,
    date: '',
    time: '',
    note: aboutProduct ? `Enquiry about ${aboutProduct.name}` : 'Appointment request from the web shop',
    status: 'requested',
    source: 'web',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}
