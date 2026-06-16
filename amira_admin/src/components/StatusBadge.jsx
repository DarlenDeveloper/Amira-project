// Maps a status string to a pill style. Shared across orders / appointments /
// products so colour language stays consistent.
const STYLES = {
  // Orders
  pending: 'badge--amber',
  processing: 'badge--sage',
  paid: 'badge--tan',
  shipped: 'badge--dark',
  delivered: 'badge--grey',
  cancelled: 'badge--rose',
  // Appointments
  requested: 'badge--amber',
  confirmed: 'badge--sage',
  completed: 'badge--grey',
  // Products
  active: 'badge--sage',
  low: 'badge--amber',
  out: 'badge--rose',
  // Conversations
  open: 'badge--sage',
  resolved: 'badge--grey',
  // Portfolio
  published: 'badge--sage',
  draft: 'badge--amber',
  concept: 'badge--grey',
};

export default function StatusBadge({ status, label }) {
  const cls = STYLES[status] ?? 'badge--grey';
  return <span className={`badge ${cls}`}>{label ?? status}</span>;
}
