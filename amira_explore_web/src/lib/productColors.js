/** Normalise Firestore `colors` array to { name, hex }[]. */
export function normalizeColors(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((c) => {
      const name = String(c?.name || '').trim();
      let hex = String(c?.hex || '').trim();
      if (hex && !hex.startsWith('#')) hex = `#${hex}`;
      if (!/^#[0-9A-Fa-f]{6}$/.test(hex)) hex = '#888888';
      return { name, hex };
    })
    .filter((c) => c.name);
}

/** Cart doc id — separate lines per colour variant. */
export function cartLineId(productId, color) {
  if (!color?.name) return productId;
  const slug = color.name.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  return slug ? `${productId}__${slug}` : productId;
}

/** Strip colour suffix from cart line id for order snapshots. */
export function baseProductId(lineId) {
  const id = String(lineId || '');
  const idx = id.indexOf('__');
  return idx === -1 ? id : id.slice(0, idx);
}
