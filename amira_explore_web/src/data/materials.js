// Mirrors the `_materials` list from the Flutter Explore screen.
// Images are served from /public/images/specialities (copied from app assets).
const DIR = '/images/specialities';

export const materials = [
  {
    image: `${DIR}/pvc marble sheet.jpeg`,
    name: 'PVC Marble Sheets',
    price: 'From $56 / sqm',
    value: 56,
    unit: 'sqm',
    badge: 'LUXURY',
    about:
      'Seamless, high-gloss marble-look sheets that bring timeless elegance to any wall — the beauty of natural stone without the weight or cost.',
  },
  {
    image: `${DIR}/bamboo wall panel.jpeg`,
    name: 'Bamboo Wall Panel',
    price: 'From $42 / sqm',
    value: 42,
    unit: 'sqm',
    badge: 'BESTSELLER',
    about:
      'Warm, sustainable bamboo panels that add natural texture and a calm, organic feel to refined interior spaces.',
  },
  {
    image: `${DIR}/wpc wall panel.jpeg`,
    name: 'WPC Wall Panel',
    price: 'From $38 / sqm',
    value: 38,
    unit: 'sqm',
    badge: null,
    about:
      'Durable wood-plastic composite panels — moisture-resistant, low-maintenance, and quietly refined.',
  },
  {
    image: `${DIR}/pvc wall panel.jpeg`,
    name: 'PVC Wall Panel',
    price: 'From $32 / sqm',
    value: 32,
    unit: 'sqm',
    badge: null,
    about:
      'Lightweight, easy-to-install PVC panels with a clean finish for fast, elegant wall transformations.',
  },
  {
    image: `${DIR}/soft stone.jpeg`,
    name: 'Soft Stone',
    price: 'From $48 / sqm',
    value: 48,
    unit: 'sqm',
    badge: null,
    about:
      'Flexible natural stone veneer that wraps curves and corners with authentic stone character.',
  },
  {
    image: `${DIR}/pu stone.jpeg`,
    name: 'PU Stone',
    price: 'From $45 / sqm',
    value: 45,
    unit: 'sqm',
    badge: null,
    about:
      'Lightweight polyurethane stone with realistic texture — the look of rock at a fraction of the weight.',
  },
  {
    image: `${DIR}/lights.jpeg`,
    name: 'Lights',
    price: 'From $25 / unit',
    value: 25,
    unit: 'unit',
    badge: 'NEW',
    about:
      'Curated ambient and accent lighting to set the mood and highlight your finest details.',
  },
  {
    image: `${DIR}/Artificial Grass.jpeg`,
    name: 'Artificial Grass & Carpets',
    price: 'From $18 / sqm',
    value: 18,
    unit: 'sqm',
    badge: null,
    about:
      'Soft, luxurious greens and carpets that bring comfort and warmth underfoot, indoors or out.',
  },
  {
    image: `${DIR}/steel profile.jpeg`,
    name: 'Steel Profile',
    price: 'From $12 / m',
    value: 12,
    unit: 'm',
    badge: null,
    about:
      'Precision steel profiles and trims for crisp, modern edges and seamless transitions.',
  },
  {
    image: `${DIR}/blinds.jpeg`,
    name: 'Blinds',
    price: 'From $35 / unit',
    value: 35,
    unit: 'unit',
    badge: null,
    about:
      'Tailored window treatments that balance privacy, light, and understated luxury.',
  },
  {
    image: `${DIR}/block boards.jpeg`,
    name: 'Block Boards',
    price: 'From $40 / sheet',
    value: 40,
    unit: 'sheet',
    badge: null,
    about:
      'Engineered block boards offering strength and a smooth base for premium joinery.',
  },
];

export const filters = ['ALL', 'FLUTED PANELS', 'WPC PANELS'];

// Top category strip — image thumbnail + label, reusing speciality imagery.
export const categories = [
  { name: 'Wall Panels', image: `${DIR}/pvc wall panel.jpeg` },
  { name: 'Marble Sheets', image: `${DIR}/pvc marble sheet.jpeg` },
  { name: 'Stone', image: `${DIR}/soft stone.jpeg` },
  { name: 'Lighting', image: `${DIR}/lights.jpeg` },
  { name: 'Flooring', image: `${DIR}/Artificial Grass.jpeg` },
  { name: 'Blinds', image: `${DIR}/blinds.jpeg` },
  { name: 'Steel', image: `${DIR}/steel profile.jpeg` },
  { name: 'Boards', image: `${DIR}/block boards.jpeg` },
];
