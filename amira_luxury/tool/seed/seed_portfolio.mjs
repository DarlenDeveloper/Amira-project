// Seeds the `portfolio` collection with showcase projects.
//
// Admin-authored; written with the Admin SDK (bypasses rules). Each entry
// references the product used on the project (productId + denormalised
// productName) — the app shows the product name where a price used to sit.
// No imageUrl here (dummy data — the client uploads real images via the admin
// dashboard); the app shows a "no image" placeholder until then.
//
// Run (see seed_products.mjs for the same steps):
//   cd amira_luxury/tool/seed && npm install
//   GOOGLE_APPLICATION_CREDENTIALS=/abs/path/key.json node seed_portfolio.mjs

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

// productId values match the product doc ids seeded by seed_products.mjs.
const portfolio = [
  {
    title: 'Living Room Design',
    room: 'Living Room',
    location: 'Kampala, UG',
    size: '60 m²',
    productId: 'pvc-marble-sheet',
    productName: 'PVC Marble Sheets',
    status: 'published',
  },
  {
    title: 'Master Suite Finish',
    room: 'Bedroom',
    location: 'Kololo, KLA',
    size: '45 m²',
    productId: 'bamboo-wall-panel',
    productName: 'Bamboo Wall Panel',
    status: 'published',
  },
  {
    title: 'Open Kitchen Concept',
    room: 'Kitchen',
    location: 'Nakasero, KLA',
    size: '80 m²',
    productId: 'pvc-marble-sheet',
    productName: 'PVC Marble Sheets',
    status: 'published',
  },
  {
    title: 'Warm Lounge Retreat',
    room: 'Living Room',
    location: 'Entebbe, UG',
    size: '52 m²',
    productId: 'soft-stone',
    productName: 'Soft Stone',
    status: 'draft',
  },
  {
    title: 'Studio Workspace',
    room: 'Office',
    location: 'Jinja, UG',
    size: '38 m²',
    productId: 'lights',
    productName: 'Lights',
    status: 'concept',
  },
];

async function seed() {
  const batch = db.batch();
  portfolio.forEach((p, i) => {
    const slug = p.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    const ref = db.collection('portfolio').doc(slug);
    batch.set(
      ref,
      { ...p, order: i, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
  await batch.commit();
  console.log(`Seeded ${portfolio.length} portfolio entries.`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
