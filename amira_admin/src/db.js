// Firestore data access for the admin dashboard: a live-collection hook plus
// thin CRUD + storage helpers. Pages subscribe with useCollection and never
// touch the SDK directly.
import { useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  query,
  where as fbWhere,
  addDoc,
  updateDoc,
  deleteDoc,
  setDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { db, storage } from './firebase.js';

/**
 * Subscribe to a collection in real time.
 * @returns {{ data: Array, loading: boolean, error: Error|null }}
 * Each item is the doc data spread with its `id`.
 */
export function useCollection(path, { whereClause } = {}) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Stable key so the effect re-subscribes only when the query changes.
  const key = `${path}|${whereClause ? whereClause.join(',') : ''}`;

  useEffect(() => {
    if (!path) {
      setData([]);
      setLoading(false);
      return undefined;
    }
    setLoading(true);
    setError(null);
    const base = collection(db, path);
    const q = whereClause
      ? query(base, fbWhere(whereClause[0], whereClause[1], whereClause[2]))
      : base;
    const unsub = onSnapshot(
      q,
      (snap) => {
        setData(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      },
    );
    return unsub;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  return { data, loading, error };
}

// ── Writes ───────────────────────────────────────────────────────────────────
export function createDoc(path, data) {
  return addDoc(collection(db, path), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

export function setDocById(path, id, data, { merge = true } = {}) {
  return setDoc(
    doc(db, path, id),
    { ...data, updatedAt: serverTimestamp() },
    { merge },
  );
}

export function updateDocById(path, id, data) {
  return updateDoc(doc(db, path, id), { ...data, updatedAt: serverTimestamp() });
}

export function deleteDocById(path, id) {
  return deleteDoc(doc(db, path, id));
}

// ── Storage ──────────────────────────────────────────────────────────────────
/** Uploads a file and returns its download URL. */
export async function uploadImage(folder, file) {
  const safe = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const path = `${folder}/${Date.now()}_${safe}`;
  const storageRef = ref(storage, path);
  await uploadBytes(storageRef, file);
  return getDownloadURL(storageRef);
}

/** Best-effort delete of a stored image by its download URL. */
export async function deleteImage(url) {
  try {
    await deleteObject(ref(storage, url));
  } catch {
    // Already gone or not a storage URL — safe to ignore.
  }
}

// ── Formatting helpers ─────────────────────────────────────────────────────────
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/** Firestore Timestamp | Date | null → "Jun 12, 2026" (or '' ). */
export function formatDate(ts) {
  const d = ts?.toDate ? ts.toDate() : ts instanceof Date ? ts : null;
  if (!d) return '';
  return `${_months[d.getMonth()]} ${String(d.getDate()).padStart(2, '0')}, ${d.getFullYear()}`;
}

/** Firestore Timestamp | Date | null → "Jun 2026" (or '' ). */
export function formatMonth(ts) {
  const d = ts?.toDate ? ts.toDate() : ts instanceof Date ? ts : null;
  if (!d) return '';
  return `${_months[d.getMonth()]} ${d.getFullYear()}`;
}
