// Appointments — "Book Appointment" requests from the app.
export const appointments = [
  { id: 'AP-2042', customer: 'Adeline Mwesigwa', email: 'adeline@example.com', type: 'Design Consultation', date: 'Jun 18, 2026', time: '10:00', status: 'confirmed', note: 'Living room feature wall — marble vs bamboo.' },
  { id: 'AP-2041', customer: 'Lela Nakato', email: 'lela@example.com', type: 'Site Visit', date: 'Jun 17, 2026', time: '14:30', status: 'requested', note: 'New apartment, full interior finishes.' },
  { id: 'AP-2040', customer: 'Priya Singh', email: 'priya@example.com', type: 'Design Consultation', date: 'Jun 15, 2026', time: '11:15', status: 'confirmed', note: 'Open kitchen concept.' },
  { id: 'AP-2039', customer: 'Marcus Otieno', email: 'marcus@example.com', type: 'Showroom Visit', date: 'Jun 14, 2026', time: '09:00', status: 'completed', note: 'Reviewed stone veneer samples.' },
  { id: 'AP-2038', customer: 'Omar Hassan', email: 'omar@example.com', type: 'Site Visit', date: 'Jun 13, 2026', time: '16:00', status: 'cancelled', note: 'Rescheduling to next month.' },
];

export const appointmentStatuses = ['requested', 'confirmed', 'completed', 'cancelled'];
