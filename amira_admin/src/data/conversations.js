// AMIRA Agent conversations — the in-app chatbot threads, for admin review.
export const conversations = [
  {
    id: 'c1',
    customer: 'Adeline Mwesigwa',
    email: 'adeline@example.com',
    updated: '12 min ago',
    status: 'open',
    messages: [
      { from: 'user', text: 'Hi, what wall finish would suit a warm-toned living room?', time: '10:02' },
      { from: 'agent', text: 'For a warm living room, our PVC Marble Sheets or Bamboo Wall Panels work beautifully. Bamboo adds organic texture, while marble brings a refined sheen.', time: '10:02' },
      { from: 'user', text: 'How much is the bamboo panel per sqm?', time: '10:04' },
      { from: 'agent', text: 'Bamboo Wall Panel starts at $42 / sqm. Would you like me to estimate coverage for your room size?', time: '10:04' },
    ],
  },
  {
    id: 'c2',
    customer: 'Daniel Kiprop',
    email: 'daniel@example.com',
    updated: '1 hour ago',
    status: 'open',
    messages: [
      { from: 'user', text: 'Do you offer lighting for a feature wall?', time: '09:15' },
      { from: 'agent', text: 'Yes — our accent Lights are ideal for feature walls, from $25 / unit. I can suggest a layout if you share a photo.', time: '09:15' },
    ],
  },
  {
    id: 'c3',
    customer: 'Yasmin Rashid',
    email: 'yasmin@example.com',
    updated: 'Yesterday',
    status: 'resolved',
    messages: [
      { from: 'user', text: 'Is soft stone suitable for a curved wall?', time: 'Jun 10' },
      { from: 'agent', text: 'Absolutely. Soft Stone is a flexible veneer that wraps curves and corners while keeping authentic stone character.', time: 'Jun 10' },
      { from: 'user', text: 'Perfect, thank you!', time: 'Jun 10' },
    ],
  },
  {
    id: 'c4',
    customer: 'Priya Singh',
    email: 'priya@example.com',
    updated: '2 days ago',
    status: 'resolved',
    messages: [
      { from: 'user', text: 'Can I book a consultation for my kitchen?', time: 'Jun 8' },
      { from: 'agent', text: 'Of course — I can set up a consultation with an Amira designer. What day works best for you?', time: 'Jun 8' },
    ],
  },
];
