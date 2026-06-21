import { useState } from 'react';
import Modal from './Modal.jsx';
import {
  createDoc,
  setDocById,
  updateDocById,
  uploadImage,
  deleteImage,
} from '../db.js';

const UNITS = ['sqm', 'unit', 'm', 'sheet'];
const STATUSES = [
  { value: 'active', label: 'In stock' },
  { value: 'low', label: 'Low stock' },
  { value: 'out', label: 'Out of stock' },
];
// Suggestions for the badge/tag (free text — type your own too).
const BADGES = ['BESTSELLER', 'NEW', 'LUXURY', 'ON DISCOUNT'];

const slugify = (s) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

let _imgKey = 0;
const nextKey = () => `img-${Date.now()}-${_imgKey++}`;

let _colorKey = 0;
const nextColorKey = () => `color-${Date.now()}-${_colorKey++}`;

function initialColors(initial) {
  if (!Array.isArray(initial?.colors)) return [];
  return initial.colors.map((c) => ({
    key: nextColorKey(),
    name: c.name || '',
    hex: c.hex || '#888888',
  }));
}

// Builds the initial gallery from an existing product's images / imageUrl.
function initialImages(initial) {
  const urls = Array.isArray(initial?.images) && initial.images.length
    ? initial.images
    : initial?.imageUrl
      ? [initial.imageUrl]
      : [];
  return urls.map((url) => ({ key: nextKey(), url, file: null, preview: url }));
}

export default function ProductForm({ initial, categories = [], onClose, onSaved }) {
  const isEdit = Boolean(initial?.id);
  const [form, setForm] = useState({
    name: initial?.name ?? '',
    category: initial?.category ?? '',
    value: initial?.value ?? '',
    unit: initial?.unit ?? 'sqm',
    stock: initial?.stock ?? 0,
    status: initial?.status ?? 'active',
    badge: initial?.badge ?? '',
    desc: initial?.desc ?? '',
    about: initial?.about ?? '',
  });
  // Ordered gallery; first item is the primary image.
  const [images, setImages] = useState(() => initialImages(initial));
  const [colors, setColors] = useState(() => initialColors(initial));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const addFiles = (e) => {
    const files = Array.from(e.target.files ?? []);
    if (!files.length) return;
    setImages((prev) => [
      ...prev,
      ...files.map((file) => ({
        key: nextKey(),
        url: null,
        file,
        preview: URL.createObjectURL(file),
      })),
    ]);
    e.target.value = ''; // allow re-picking the same file
  };

  const removeImage = (key) =>
    setImages((prev) => prev.filter((img) => img.key !== key));

  const makePrimary = (key) =>
    setImages((prev) => {
      const idx = prev.findIndex((img) => img.key === key);
      if (idx <= 0) return prev;
      const copy = [...prev];
      const [item] = copy.splice(idx, 1);
      copy.unshift(item);
      return copy;
    });

  const addColor = () =>
    setColors((prev) => [...prev, { key: nextColorKey(), name: '', hex: '#888888' }]);

  const updateColor = (key, field, value) =>
    setColors((prev) =>
      prev.map((c) => (c.key === key ? { ...c, [field]: value } : c)),
    );

  const removeColor = (key) => setColors((prev) => prev.filter((c) => c.key !== key));

  const submit = async (e) => {
    e.preventDefault();
    if (!form.name.trim()) return setError('Name is required.');
    if (form.value === '' || Number.isNaN(Number(form.value)))
      return setError('Enter a valid price.');
    setError('');
    setBusy(true);
    try {
      // Upload any newly-added files, preserving gallery order.
      const urls = [];
      for (const img of images) {
        urls.push(img.file ? await uploadImage('products', img.file) : img.url);
      }

      // Storage cleanup: existing URLs that were removed from the gallery.
      const kept = new Set(urls);
      const previous = Array.isArray(initial?.images) && initial.images.length
        ? initial.images
        : initial?.imageUrl
          ? [initial.imageUrl]
          : [];
      await Promise.all(
        previous.filter((u) => !kept.has(u)).map((u) => deleteImage(u)),
      );

      const data = {
        name: form.name.trim(),
        imageKey: initial?.imageKey ?? slugify(form.name),
        category: form.category.trim(),
        value: Number(form.value),
        unit: form.unit,
        stock: Number(form.stock) || 0,
        status: form.status,
        badge: form.badge.trim() || null,
        desc: form.desc.trim(),
        about: form.about.trim(),
        order: initial?.order ?? 0,
        images: urls,
        imageUrl: urls[0] ?? null, // primary — what the app displays
        colors: colors
          .map((c) => {
            const name = c.name.trim();
            let hex = c.hex.trim();
            if (hex && !hex.startsWith('#')) hex = `#${hex}`;
            return { name, hex };
          })
          .filter((c) => c.name),
      };

      if (isEdit) {
        await updateDocById('products', initial.id, data);
      } else {
        const slug = slugify(form.name);
        if (slug) await setDocById('products', slug, data);
        else await createDoc('products', data);
      }
      onSaved();
    } catch (err) {
      setError(err.message ?? 'Could not save. Please try again.');
      setBusy(false);
    }
  };

  return (
    <Modal
      title={isEdit ? 'Edit product' : 'New product'}
      onClose={onClose}
      footer={
        <>
          <button type="button" className="ghost-btn" onClick={onClose} disabled={busy}>
            Cancel
          </button>
          <button type="submit" form="product-form" className="primary-btn" disabled={busy}>
            {busy ? 'Saving…' : isEdit ? 'Save changes' : 'Create product'}
          </button>
        </>
      }
    >
      <form id="product-form" className="form" onSubmit={submit}>
        {/* Image gallery */}
        <div className="form-field">
          <span>Images {images.length > 0 && `(${images.length})`}</span>
          <div className="img-gallery">
            {images.map((img, i) => (
              <div key={img.key} className={`img-tile${i === 0 ? ' img-tile--primary' : ''}`}>
                <img src={img.preview} alt="" />
                {i === 0 && <span className="img-primary-badge">Primary</span>}
                <button
                  type="button"
                  className="img-remove"
                  aria-label="Remove image"
                  onClick={() => removeImage(img.key)}
                >
                  ×
                </button>
                {i !== 0 && (
                  <button
                    type="button"
                    className="img-make-primary"
                    onClick={() => makePrimary(img.key)}
                  >
                    Make primary
                  </button>
                )}
              </div>
            ))}
            <label className="img-add">
              <span>+ Add</span>
              <input type="file" accept="image/*" multiple onChange={addFiles} hidden />
            </label>
          </div>
        </div>

        <label className="form-field">
          <span>Name</span>
          <input value={form.name} onChange={set('name')} placeholder="PVC Marble Sheets" />
        </label>

        <div className="form-row">
          <label className="form-field">
            <span>Category</span>
            <input
              value={form.category}
              onChange={set('category')}
              placeholder="Wall Panels"
              list="category-options"
            />
            <datalist id="category-options">
              {categories.map((c) => (
                <option key={c} value={c} />
              ))}
            </datalist>
          </label>
          <label className="form-field">
            <span>Tag / badge</span>
            <input
              value={form.badge}
              onChange={set('badge')}
              placeholder="e.g. BESTSELLER"
              list="badge-options"
            />
            <datalist id="badge-options">
              {BADGES.map((b) => (
                <option key={b} value={b} />
              ))}
            </datalist>
          </label>
        </div>

        <div className="form-row">
          <label className="form-field">
            <span>Price (UGX)</span>
            <input type="number" min="0" value={form.value} onChange={set('value')} />
          </label>
          <label className="form-field">
            <span>Unit</span>
            <select value={form.unit} onChange={set('unit')}>
              {UNITS.map((u) => (
                <option key={u} value={u}>{u}</option>
              ))}
            </select>
          </label>
          <label className="form-field">
            <span>Stock</span>
            <input type="number" min="0" value={form.stock} onChange={set('stock')} />
          </label>
        </div>

        <label className="form-field">
          <span>Status</span>
          <select value={form.status} onChange={set('status')}>
            {STATUSES.map((s) => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
        </label>

        <div className="form-field">
          <span>Available colours</span>
          <p className="form-hint">Shoppers can pick a colour when adding to cart. Leave empty if not applicable.</p>
          <div className="color-editor">
            {colors.map((c) => (
              <div className="color-row" key={c.key}>
                <input
                  type="color"
                  className="color-picker"
                  value={c.hex}
                  onChange={(e) => updateColor(c.key, 'hex', e.target.value)}
                  aria-label="Colour swatch"
                />
                <input
                  className="color-name"
                  value={c.name}
                  onChange={(e) => updateColor(c.key, 'name', e.target.value)}
                  placeholder="e.g. Ivory White"
                />
                <button type="button" className="color-remove" onClick={() => removeColor(c.key)} aria-label="Remove colour">
                  ×
                </button>
              </div>
            ))}
            <button type="button" className="color-add" onClick={addColor}>
              + Add colour
            </button>
          </div>
        </div>

        <label className="form-field">
          <span>Short tagline</span>
          <input value={form.desc} onChange={set('desc')} placeholder="Seamless marble-look wall cladding" />
        </label>

        <label className="form-field">
          <span>Description</span>
          <textarea rows={3} value={form.about} onChange={set('about')} />
        </label>

        {error && <p className="form-error">{error}</p>}
      </form>
    </Modal>
  );
}
