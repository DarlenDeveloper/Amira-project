// Products mirror the app's Explore catalogue (the 11 specialities).
const DIR = '/images/specialities';

export const products = [
  { image: `${DIR}/pvc marble sheet.jpeg`, name: 'PVC Marble Sheets', category: 'Marble Sheets', value: 56, unit: 'sqm', stock: 240, status: 'active' },
  { image: `${DIR}/bamboo wall panel.jpeg`, name: 'Bamboo Wall Panel', category: 'Wall Panels', value: 42, unit: 'sqm', stock: 180, status: 'active' },
  { image: `${DIR}/wpc wall panel.jpeg`, name: 'WPC Wall Panel', category: 'Wall Panels', value: 38, unit: 'sqm', stock: 64, status: 'active' },
  { image: `${DIR}/pvc wall panel.jpeg`, name: 'PVC Wall Panel', category: 'Wall Panels', value: 32, unit: 'sqm', stock: 12, status: 'low' },
  { image: `${DIR}/soft stone.jpeg`, name: 'Soft Stone', category: 'Stone', value: 48, unit: 'sqm', stock: 96, status: 'active' },
  { image: `${DIR}/pu stone.jpeg`, name: 'PU Stone', category: 'Stone', value: 45, unit: 'sqm', stock: 0, status: 'out' },
  { image: `${DIR}/lights.jpeg`, name: 'Lights', category: 'Lighting', value: 25, unit: 'unit', stock: 320, status: 'active' },
  { image: `${DIR}/Artificial Grass.jpeg`, name: 'Artificial Grass & Carpets', category: 'Flooring', value: 18, unit: 'sqm', stock: 150, status: 'active' },
  { image: `${DIR}/steel profile.jpeg`, name: 'Steel Profile', category: 'Steel', value: 12, unit: 'm', stock: 8, status: 'low' },
  { image: `${DIR}/blinds.jpeg`, name: 'Blinds', category: 'Blinds', value: 35, unit: 'unit', stock: 74, status: 'active' },
  { image: `${DIR}/block boards.jpeg`, name: 'Block Boards', category: 'Boards', value: 40, unit: 'sheet', stock: 110, status: 'active' },
];

export const productCategories = [
  'Wall Panels', 'Marble Sheets', 'Stone', 'Lighting', 'Flooring', 'Blinds', 'Steel', 'Boards',
];
