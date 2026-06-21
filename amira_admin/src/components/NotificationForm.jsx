import { useState } from 'react';
import Modal from './Modal.jsx';
import { createDoc } from '../db.js';
import { serverTimestamp } from 'firebase/firestore';

const TYPES = [
  { value: 'collection', label: 'Collection' },
  { value: 'offer', label: 'Offer' },
  { value: 'order', label: 'Order' },
  { value: 'design', label: 'Design' },
];

export default function NotificationForm({ onClose, onSaved }) {
  const [form, setForm] = useState({
    type: 'collection',
    title: '',
    body: '',
    audience: 'all',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) {
      setError('Title and message are required.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      await createDoc('notifications', {
        type: form.type,
        title: form.title.trim(),
        body: form.body.trim(),
        audience: form.audience.trim() || 'all',
        sentAt: serverTimestamp(),
        delivered: 0,
      });
      onSaved?.();
      onClose();
    } catch (err) {
      setError(err.message || 'Could not send notification.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal
      title="New notification"
      onClose={onClose}
      footer={(
        <>
          <button type="button" className="ghost-btn" onClick={onClose}>Cancel</button>
          <button type="submit" form="notif-form" className="primary-btn" disabled={busy}>
            {busy ? 'Sending…' : 'Send to app & web'}
          </button>
        </>
      )}
    >
      <form id="notif-form" className="form" onSubmit={handleSubmit}>
        <label className="form-field">
          <span>Type</span>
          <select value={form.type} onChange={set('type')}>
            {TYPES.map((t) => (
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
        </label>

        <label className="form-field">
          <span>Title</span>
          <input
            type="text"
            value={form.title}
            onChange={set('title')}
            placeholder="New Collection Added"
            required
          />
        </label>

        <label className="form-field">
          <span>Message</span>
          <textarea
            rows={4}
            value={form.body}
            onChange={set('body')}
            placeholder="Explore our latest PVC marble sheets…"
            required
          />
        </label>

        <label className="form-field">
          <span>Audience</span>
          <select value={form.audience} onChange={set('audience')}>
            <option value="all">All users & guests</option>
          </select>
        </label>

        {error && <p className="form-error">{error}</p>}
      </form>
    </Modal>
  );
}
