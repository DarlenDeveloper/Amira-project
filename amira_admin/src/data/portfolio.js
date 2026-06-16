// Portfolio — completed/showcase interior projects (the app's "Our Portfolio").
const DIR = '/images/portfolio';

export const portfolio = [
  { image: `${DIR}/living-room.jpg`, title: 'Living Room Design', room: 'Living Room', location: 'Kampala, UG', size: '60 m²', price: 'UGX 68,000,000', status: 'published' },
  { image: `${DIR}/master-suite.jpg`, title: 'Master Suite Finish', room: 'Bedroom', location: 'Kololo, KLA', size: '45 m²', price: 'UGX 51,000,000', status: 'published' },
  { image: `${DIR}/open-kitchen.jpg`, title: 'Open Kitchen Concept', room: 'Kitchen', location: 'Nakasero, KLA', size: '80 m²', price: 'UGX 88,000,000', status: 'published' },
  { image: `${DIR}/lounge.jpg`, title: 'Warm Lounge Retreat', room: 'Living Room', location: 'Entebbe, UG', size: '52 m²', price: 'UGX 60,000,000', status: 'draft' },
  { image: `${DIR}/studio.jpg`, title: 'Studio Workspace', room: 'Office', location: 'Jinja, UG', size: '38 m²', price: 'UGX 42,000,000', status: 'concept' },
];

export const portfolioStatuses = ['published', 'draft', 'concept'];
