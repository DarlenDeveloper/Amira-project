// UGX is the only currency. Amounts get large, so show them compactly:
// UGX 1.2M, 700K, 20K, 1K, 1B. Values below 1,000 are shown in full.
const trim = (v) => {
  let s = v.toFixed(1);
  if (s.endsWith('.0')) s = s.slice(0, -2);
  return s;
};

const compact = (n) => {
  const num = Number(n) || 0;
  const a = Math.abs(num);
  let body;
  if (a >= 1e9) body = trim(a / 1e9) + 'B';
  else if (a >= 1e6) body = trim(a / 1e6) + 'M';
  else if (a >= 1e3) body = trim(a / 1e3) + 'K';
  else body = String(Math.round(a));
  return (num < 0 ? '-' : '') + body;
};

export const money = (n) => 'UGX ' + compact(n);

export const titleCase = (s) => s.charAt(0).toUpperCase() + s.slice(1);
