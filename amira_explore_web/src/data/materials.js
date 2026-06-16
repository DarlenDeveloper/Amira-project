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
    specs: [
      { label: 'Material', value: 'PVC composite' },
      { label: 'Thickness', value: '3 mm' },
      { label: 'Finish', value: 'High-gloss marble' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'Natural bamboo' },
      { label: 'Thickness', value: '12 mm' },
      { label: 'Finish', value: 'Natural matte' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'Wood-plastic composite' },
      { label: 'Thickness', value: '9 mm' },
      { label: 'Finish', value: 'Wood-grain' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'PVC' },
      { label: 'Thickness', value: '8 mm' },
      { label: 'Finish', value: 'Matte' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'Flexible stone veneer' },
      { label: 'Thickness', value: '2 mm' },
      { label: 'Finish', value: 'Natural stone' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'Polyurethane' },
      { label: 'Weight', value: 'Lightweight' },
      { label: 'Finish', value: 'Textured stone' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Type', value: 'Ambient & accent' },
      { label: 'Source', value: 'LED' },
      { label: 'Tone', value: 'Warm white' },
      { label: 'Sold by', value: 'Unit' },
    ],
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
    specs: [
      { label: 'Material', value: 'Synthetic turf' },
      { label: 'Pile height', value: '25 mm' },
      { label: 'Use', value: 'Indoor / outdoor' },
      { label: 'Sold by', value: 'Square metre' },
    ],
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
    specs: [
      { label: 'Material', value: 'Stainless steel' },
      { label: 'Finish', value: 'Brushed / gold' },
      { label: 'Use', value: 'Trims & edges' },
      { label: 'Sold by', value: 'Metre' },
    ],
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
    specs: [
      { label: 'Type', value: 'Roller / zebra' },
      { label: 'Material', value: 'Polyester' },
      { label: 'Operation', value: 'Manual / motorised' },
      { label: 'Sold by', value: 'Unit' },
    ],
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
    specs: [
      { label: 'Material', value: 'Engineered wood' },
      { label: 'Thickness', value: '18 mm' },
      { label: 'Core', value: 'Softwood batten' },
      { label: 'Sold by', value: 'Sheet' },
    ],
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
