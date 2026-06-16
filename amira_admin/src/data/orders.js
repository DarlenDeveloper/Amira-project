// Dummy orders — replaced by Firestore data when the backend is wired.
export const orders = [
  { id: 'AM-10248', customer: 'Adeline Mwesigwa', email: 'adeline@example.com', date: 'Jun 12, 2026', items: 3, status: 'processing', total: 1240 },
  { id: 'AM-10247', customer: 'Daniel Kiprop', email: 'daniel@example.com', date: 'Jun 11, 2026', items: 2, status: 'shipped', total: 895 },
  { id: 'AM-10246', customer: 'Yasmin Rashid', email: 'yasmin@example.com', date: 'Jun 10, 2026', items: 5, status: 'paid', total: 2450 },
  { id: 'AM-10245', customer: 'Marcus Otieno', email: 'marcus@example.com', date: 'Jun 09, 2026', items: 1, status: 'delivered', total: 320 },
  { id: 'AM-10244', customer: 'Lela Nakato', email: 'lela@example.com', date: 'Jun 09, 2026', items: 4, status: 'processing', total: 1785 },
  { id: 'AM-10243', customer: 'Omar Hassan', email: 'omar@example.com', date: 'Jun 08, 2026', items: 1, status: 'cancelled', total: 560 },
  { id: 'AM-10242', customer: 'Priya Singh', email: 'priya@example.com', date: 'Jun 07, 2026', items: 3, status: 'delivered', total: 1425 },
  { id: 'AM-10241', customer: 'Brian Ssali', email: 'brian@example.com', date: 'Jun 06, 2026', items: 2, status: 'pending', total: 680 },
];

// Order in which status filters are shown.
export const orderStatuses = [
  'pending',
  'processing',
  'paid',
  'shipped',
  'delivered',
  'cancelled',
];
