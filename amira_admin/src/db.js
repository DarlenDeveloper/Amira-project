// Firestore data access for the admin dashboard: a live-collection hook plus
// thin CRUD + storage helpers. Pages subscribe with useCollection and never
// touch the SDK directly.
import { useCallback, useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  query,
  where as fbWhere,
  orderBy,
  limit,
  startAfter,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  setDoc,
  serverTimestamp,
  increment,
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

/**
 * Paginated collection fetch (one-shot pages, not live after first load).
 * @returns {{ data, loading, error, hasMore, loadMore, refresh }}
 */
export function usePaginatedCollection(
  path,
  { whereClause, orderByField = 'createdAt', orderDir = 'desc', pageSize = 50 } = {},
) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState(null);
  const [generation, setGeneration] = useState(0);

  const key = `${path}|${whereClause ? whereClause.join(',') : ''}|${orderByField}|${orderDir}|${pageSize}|${generation}`;

  const buildQuery = useCallback(
    (cursor) => {
      const base = collection(db, path);
      const constraints = [];
      if (whereClause) constraints.push(fbWhere(whereClause[0], whereClause[1], whereClause[2]));
      constraints.push(orderBy(orderByField, orderDir));
      if (cursor) constraints.push(startAfter(cursor));
      constraints.push(limit(pageSize));
      return query(base, ...constraints);
    },
    [path, whereClause, orderByField, orderDir, pageSize],
  );

  const refresh = useCallback(() => {
    setData([]);
    setLastDoc(null);
    setHasMore(true);
    setGeneration((g) => g + 1);
  }, []);

  useEffect(() => {
    if (!path) {
      setData([]);
      setLoading(false);
      return undefined;
    }
    let cancelled = false;
    setLoading(true);
    setError(null);
    getDocs(buildQuery(null))
      .then((snap) => {
        if (cancelled) return;
        const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setData(rows);
        setLastDoc(snap.docs[snap.docs.length - 1] ?? null);
        setHasMore(snap.docs.length >= pageSize);
        setLoading(false);
      })
      .catch((err) => {
        if (cancelled) return;
        setError(err);
        setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [key, path, buildQuery, pageSize]);

  const loadMore = useCallback(async () => {
    if (!hasMore || loading || !lastDoc) return;
    setLoading(true);
    try {
      const snap = await getDocs(buildQuery(lastDoc));
      const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setData((prev) => [...prev, ...rows]);
      setLastDoc(snap.docs[snap.docs.length - 1] ?? lastDoc);
      setHasMore(snap.docs.length >= pageSize);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [hasMore, loading, lastDoc, buildQuery, pageSize]);

  return { data, loading, error, hasMore, loadMore, refresh };
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

// ── Conversations: human intervention ──────────────────────────────────────────
/**
 * Take over a conversation from the AI. Sets the thread to human mode so the
 * `chatAgent` function stops auto-replying — from here it's just the customer
 * and the admin. One-way by design, but modeled as a `mode` field so a future
 * "hand back to AI" is a data-free change.
 */
export function interveneConversation(conversationId) {
  return updateDoc(doc(db, 'conversations', conversationId), {
    mode: 'human',
    interventionAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

/**
 * Post an admin reply into a conversation thread and bump the thread summary so
 * it sorts to the top. Messages use a `time` field (matching the mobile app and
 * the Cloud Function), not `createdAt`.
 */
export async function sendAdminMessage(conversationId, text) {
  const clean = String(text || '').trim();
  if (!clean) return;
  await addDoc(collection(db, `conversations/${conversationId}/messages`), {
    from: 'admin',
    text: clean,
    status: 'sent',
    time: serverTimestamp(),
  });
  await updateDoc(doc(db, 'conversations', conversationId), {
    lastMessage: clean,
    lastFrom: 'admin',
    messageCount: increment(1),
    updatedAt: serverTimestamp(),
  });
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

/** Firestore Timestamp | Date | null → "Jun 12, 2026, 3:45 PM" (or '' ). */
export function formatDateTime(ts) {
  const d = ts?.toDate ? ts.toDate() : ts instanceof Date ? ts : null;
  if (!d) return '';
  const hours = d.getHours();
  const minutes = String(d.getMinutes()).padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  const h12 = hours % 12 || 12;
  return `${_months[d.getMonth()]} ${String(d.getDate()).padStart(2, '0')}, ${d.getFullYear()}, ${h12}:${minutes} ${ampm}`;
}
