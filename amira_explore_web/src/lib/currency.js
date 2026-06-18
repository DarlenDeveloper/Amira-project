// Currency formatting for Amira — ported from the Flutter app's currency.dart
// so the web shop displays prices identically. Amira prices in UGX (Ugandan
// shillings); amounts get large, so they're shown compactly (UGX 1.2M, 700K).

function trim(v) {
  let s = v.toFixed(1);
  if (s.endsWith('.0')) s = s.slice(0, -2);
  return s;
}

/**
 * Formats a number as a compact UGX amount, e.g. "UGX 1.2M", "UGX 700K".
 * Values below 1,000 are shown in full ("UGX 850").
 */
export function formatUgx(value) {
  const n = Number(value) || 0;
  const a = Math.abs(n);
  let body;
  if (a >= 1e9) body = `${trim(a / 1e9)}B`;
  else if (a >= 1e6) body = `${trim(a / 1e6)}M`;
  else if (a >= 1e3) body = `${trim(a / 1e3)}K`;
  else body = String(Math.round(a));
  return `UGX ${n < 0 ? '-' : ''}${body}`;
}

/** Price label for a product, e.g. "From UGX 56K / sqm". */
export function priceLabel(value, unit) {
  return `From ${formatUgx(value)} / ${unit || 'unit'}`;
}
