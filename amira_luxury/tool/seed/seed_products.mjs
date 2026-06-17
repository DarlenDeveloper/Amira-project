// Seeds the `products` collection with Amira's 11 specialities.
//
// Products are admin-authored; this script writes with the Admin SDK, which
// bypasses Firestore security rules. Doc id == imageKey (stable slug) so both
// the app and the admin reference the same ids. Re-running is idempotent
// (merge writes), so it's safe to run again after editing values.
//
// ── Run ───────────────────────────────────────────────────────────────────
//   1. From the Firebase console (Project settings → Service accounts) download
//      a service-account key JSON for project "amira-interiors".
//   2. cd amira_luxury/tool/seed
//   3. npm install
//   4. GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/serviceAccountKey.json \
//        node seed_products.mjs
//
// Keep the fields in sync with .kiro/steering/data-model.md. Products have no
// imageUrl here (these seeds are dummy data — the client replaces them and
// uploads real images via the admin dashboard); the app shows a "no image"
// placeholder until an imageUrl is set.

import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
initializeApp({
  credential: keyPath
    ? cert(JSON.parse(readFileSync(keyPath, 'utf8')))
    : applicationDefault(),
});

const db = getFirestore();

const products = [
  {
    imageKey: 'pvc-marble-sheet',
    name: 'PVC Marble Sheets',
    category: 'Marble Sheets',
    value: 56,
    unit: 'sqm',
    badge: 'LUXURY',
    desc: 'Seamless marble-look wall cladding',
    about:
      'Seamless, high-gloss marble-look sheets that bring timeless elegance to any wall — the beauty of natural stone without the weight or cost.',
    stock: 240,
    status: 'active',
  },
  {
    imageKey: 'bamboo-wall-panel',
    name: 'Bamboo Wall Panel',
    category: 'Wall Panels',
    value: 42,
    unit: 'sqm',
    badge: 'BESTSELLER',
    desc: 'Natural, sustainable wall texture',
    about:
      'Warm, sustainable bamboo panels that add natural texture and a calm, organic feel to refined interior spaces.',
    stock: 180,
    status: 'active',
  },
  {
    imageKey: 'wpc-wall-panel',
    name: 'WPC Wall Panel',
    category: 'Wall Panels',
    value: 38,
    unit: 'sqm',
    badge: null,
    desc: 'Durable wood-plastic composite',
    about:
      'Durable wood-plastic composite panels — moisture-resistant, low-maintenance, and quietly refined.',
    stock: 64,
    status: 'active',
  },
  {
    imageKey: 'pvc-wall-panel',
    name: 'PVC Wall Panel',
    category: 'Wall Panels',
    value: 32,
    unit: 'sqm',
    badge: null,
    desc: 'Lightweight, easy-fit wall finish',
    about:
      'Lightweight, easy-to-install PVC panels with a clean finish for fast, elegant wall transformations.',
    stock: 12,
    status: 'low',
  },
  {
    imageKey: 'soft-stone',
    name: 'Soft Stone',
    category: 'Stone',
    value: 48,
    unit: 'sqm',
    badge: null,
    desc: 'Flexible natural stone veneer',
    about:
      'Flexible natural stone veneer that wraps curves and corners with authentic stone character.',
    stock: 96,
    status: 'active',
  },
  {
    imageKey: 'pu-stone',
    name: 'PU Stone',
    category: 'Stone',
    value: 45,
    unit: 'sqm',
    badge: null,
    desc: 'Lightweight polyurethane stone',
    about:
      'Lightweight polyurethane stone with realistic texture — the look of rock at a fraction of the weight.',
    stock: 0,
    status: 'out',
  },
  {
    imageKey: 'lights',
    name: 'Lights',
    category: 'Lighting',
    value: 25,
    unit: 'unit',
    badge: 'NEW',
    desc: 'Ambient & accent lighting',
    about:
      'Curated ambient and accent lighting to set the mood and highlight your finest details.',
    stock: 320,
    status: 'active',
  },
  {
    imageKey: 'artificial-grass',
    name: 'Artificial Grass & Carpets',
    category: 'Flooring',
    value: 18,
    unit: 'sqm',
    badge: null,
    desc: 'Soft greens & floor textures',
    about:
      'Soft, luxurious greens and carpets that bring comfort and warmth underfoot, indoors or out.',
    stock: 150,
    status: 'active',
  },
  {
    imageKey: 'steel-profile',
    name: 'Steel Profile',
    category: 'Steel',
    value: 12,
    unit: 'm',
    badge: null,
    desc: 'Precision metal trims & frames',
    about:
      'Precision steel profiles and trims for crisp, modern edges and seamless transitions.',
    stock: 8,
    status: 'low',
  },
  {
    imageKey: 'blinds',
    name: 'Blinds',
    category: 'Blinds',
    value: 35,
    unit: 'unit',
    badge: null,
    desc: 'Tailored window treatments',
    about:
      'Tailored window treatments that balance privacy, light, and understated luxury.',
    stock: 74,
    status: 'active',
  },
  {
    imageKey: 'block-boards',
    name: 'Block Boards',
    category: 'Boards',
    value: 40,
    unit: 'sheet',
    badge: null,
    desc: 'Engineered wood panels',
    about:
      'Engineered block boards offering strength and a smooth base for premium joinery.',
    stock: 110,
    status: 'active',
  },
];

async function seed() {
  const batch = db.batch();
  products.forEach((p, i) => {
    const ref = db.collection('products').doc(p.imageKey);
    batch.set(
      ref,
      { ...p, order: i, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
  await batch.commit();
  console.log(`Seeded ${products.length} products.`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
