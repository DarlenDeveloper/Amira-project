import { useState } from 'react';
import Modal from './Modal.jsx';
import {
  createDoc,
  setDocById,
  updateDocById,
  uploadImage,
  deleteImage,
} from '../db.js';

const ROOMS = ['Living Room', 'Bedroom', 'Kitchen', 'Office', 'Bathroom', 'Dining', 'Outdoor'];
const STATUSES = [
  { value: 'published', label: 'Published' },
  { value: 'draft', label: 'Draft' },
  { value: 'concept', label: 'Concept' },
];

const slugify = (s) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

// Create / edit a portfolio project. Mirrors ProductForm: a single hero image
// (published projects feed the web hero carousel), project details, and a
// product picker that denormalises productId + productName per the data model.
export default function PortfolioForm({ initial, products = [], onClose, onSaved }) {
  const isEdit = Boolean(initial?.id);
  const [form, setForm] = useState({
    title: initial?.title ?? '',
    room: initial?.room ?? '',
    location: initial?.location ?? '',
    size: initial?.size ?? '',
    productId: initial?.productId ?? '',
    status: initial?.status ?? 'published',
    order: initial?.order ?? 0,
  });
  // Single image: { url, file, preview } or null.
  const [image, setImage] = useState(() =>
    initial?.imageUrl ? { url: initial.imageUrl, file: null, preview: initial.imageUrl } : null,
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const pickImage = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImage({ url: null, file, preview: URL.createObjectURL(file) });
    e.target.value = '';
  };

  const submit = async (e) => {
    e.preventDefault();
    if (!form.title.trim()) return setError('Title is required.');
    setError('');
    setBusy(true);
    try {
      // Upload a newly-picked image; otherwise keep the existing URL.
      let imageUrl = image?.url ?? null;
      if (image?.file) imageUrl = await uploadImage('portfolio', image.file);

      // Clean up a replaced/removed image from storage.
      if (initial?.imageUrl && initial.imageUrl !== imageUrl) {
        await deleteImage(initial.imageUrl);
      }

      const picked = products.find((p) => p.id === form.productId);
      const data = {
        title: form.title.trim(),
        imageUrl,
        room: form.room.trim(),
        location: form.location.trim(),
        size: form.size.trim(),
        productId: form.productId || '',
        productName: picked?.name ?? initial?.productName ?? '',
        status: form.status,
        order: Number(form.order) || 0,
      };

      if (isEdit) {
        await updateDocById('portfolio', initial.id, data);
      } else {
        const slug = slugify(form.title);
        if (slug) await setDocById('portfolio', slug, data);
        else await createDoc('portfolio', data);
      }
      onSaved();
    } catch (err) {
      setError(err.message ?? 'Could not save. Please try again.');
      setBusy(false);
    }
  };

  return (
    <Modal
      title={isEdit ? 'Edit project' : 'New project'}
      onClose={onClose}
      footer={
        <>
          <button type="button" className="ghost-btn" onClick={onClose} disabled={busy}>
            Cancel
          </button>
          <button type="submit" form="portfolio-form" className="primary-btn" disabled={busy}>
            {busy ? 'Saving…' : isEdit ? 'Save changes' : 'Create project'}
          </button>
        </>
      }
    >
      <form id="portfolio-form" className="form" onSubmit={submit}>
        {/* Hero image */}
        <div className="form-field">
          <span>Project image</span>
          <div className="img-gallery">
            {image ? (
              <div className="img-tile img-tile--primary">
                <img src={image.preview} alt="" />
                <button type="button" className="img-remove" aria-label="Remove image" onClick={() => setImage(null)}>
                  ×
                </button>
              </div>
            ) : (
              <label className="img-add">
                <span>+ Add</span>
                <input type="file" accept="image/*" onChange={pickImage} hidden />
              </label>
            )}
          </div>
          <small className="field-hint">Published projects appear in the web hero carousel.</small>
        </div>

        <label className="form-field">
          <span>Title</span>
          <input value={form.title} onChange={set('title')} placeholder="Living Room Design" />
        </label>

        <div className="form-row">
          <label className="form-field">
            <span>Room</span>
            <input value={form.room} onChange={set('room')} placeholder="Living Room" list="room-options" />
            <datalist id="room-options">
              {ROOMS.map((r) => (
                <option key={r} value={r} />
              ))}
            </datalist>
          </label>
          <label className="form-field">
            <span>Size</span>
            <input value={form.size} onChange={set('size')} placeholder="60 m²" />
          </label>
        </div>

        <label className="form-field">
          <span>Location</span>
          <input value={form.location} onChange={set('location')} placeholder="Kampala, UG" />
        </label>

        <div className="form-row">
          <label className="form-field">
            <span>Product used</span>
            <select value={form.productId} onChange={set('productId')}>
              <option value="">— None —</option>
              {products.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </label>
          <label className="form-field">
            <span>Status</span>
            <select value={form.status} onChange={set('status')}>
              {STATUSES.map((s) => (
                <option key={s.value} value={s.value}>{s.label}</option>
              ))}
            </select>
          </label>
        </div>

        <label className="form-field">
          <span>Display order</span>
          <input type="number" min="0" value={form.order} onChange={set('order')} />
          <small className="field-hint">Lower numbers appear first.</small>
        </label>

        {error && <p className="form-error">{error}</p>}
      </form>
    </Modal>
  );
}
