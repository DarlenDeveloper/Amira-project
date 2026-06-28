// Re-seeds the Amira catalogue with the correct two-level shape:
//   categories/{slug}            ← the 11 company specialities (the categories)
//   products/{slug}              ← actual products, each tied to a category
//
// Products carry BOTH a `categoryId` (slug ref) and a denormalised `category`
// name string, so the existing apps (which derive their category filters from
// the `category` string) keep working unchanged while the real hierarchy is in
// place.
//
// This script is DESTRUCTIVE for the `products` collection: it deletes every
// existing product doc first, then writes the new categories + sample products.
// The sample products are placeholders (no images) for the client to refine in
// the admin dashboard.
//
// ── Run ───────────────────────────────────────────────────────────────────
//   cd amira_luxury/tool/seed
//   npm install
//   GOOGLE_APPLICATION_CREDENTIALS=/abs/path/to/serviceAccountKey.json \
//     node seed_catalogue.mjs

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

// ── The 11 categories (company specialities) ───────────────────────────────
// `imageKey` matches the bundled speciality assets the apps already ship.
const categories = [
  { slug: 'pvc-marble-sheets', name: 'PVC Marble Sheets', imageKey: 'pvc-marble-sheets', desc: 'Seamless marble-look wall cladding' },
  { slug: 'bamboo-wall-panel', name: 'Bamboo Wall Panel', imageKey: 'bamboo-wall-panel', desc: 'Natural, sustainable wall texture' },
  { slug: 'wpc-wall-panel', name: 'WPC Wall Panel', imageKey: 'wpc-wall-panel', desc: 'Durable wood-plastic composite panels' },
  { slug: 'pvc-wall-panel', name: 'PVC Wall Panel', imageKey: 'pvc-wall-panel', desc: 'Lightweight, easy-fit wall finishes' },
  { slug: 'soft-stone', name: 'Soft Stone', imageKey: 'soft-stone', desc: 'Flexible natural stone veneer' },
  { slug: 'pu-stone', name: 'PU Stone', imageKey: 'pu-stone', desc: 'Lightweight polyurethane stone' },
  { slug: 'lights', name: 'Lights', imageKey: 'lights', desc: 'Ambient & accent lighting' },
  { slug: 'artificial-grass-carpets', name: 'Artificial Grass & Carpets', imageKey: 'artificial-grass', desc: 'Soft greens & floor textures' },
  { slug: 'steel-profile', name: 'Steel Profile', imageKey: 'steel-profile', desc: 'Precision metal trims & frames' },
  { slug: 'blinds', name: 'Blinds', imageKey: 'blinds', desc: 'Tailored window treatments' },
  { slug: 'block-boards', name: 'Block Boards', imageKey: 'block-boards', desc: 'Engineered wood panels' },
];

// ── Sample products per category (placeholders — refine in the admin) ───────
// Keyed by category slug. Each entry becomes products/{categorySlug}-{n}.
const sampleProducts = {
  'pvc-marble-sheets': [
    { name: 'Carrara White Marble Sheet', value: 56, unit: 'sqm', badge: 'LUXURY', desc: 'Classic white marble with soft grey veining', about: 'High-gloss PVC marble sheet that captures the timeless elegance of Carrara marble — light, durable, and easy to install.', stock: 240, status: 'active' },
    { name: 'Emperador Brown Marble Sheet', value: 58, unit: 'sqm', desc: 'Warm brown marble with golden veins', about: 'Rich Emperador-look sheet for statement walls and feature panels, bringing depth and warmth to refined interiors.', stock: 160, status: 'active' },
  ],
  'bamboo-wall-panel': [
    { name: 'Natural Bamboo Panel', value: 42, unit: 'sqm', badge: 'BESTSELLER', desc: 'Warm, organic bamboo texture', about: 'Sustainable bamboo panel that adds a calm, natural texture to living and hospitality spaces.', stock: 180, status: 'active' },
    { name: 'Charcoal Bamboo Panel', value: 45, unit: 'sqm', desc: 'Deep charcoal-toned bamboo finish', about: 'Darker carbonised bamboo panel for dramatic, contemporary feature walls.', stock: 90, status: 'active' },
  ],
  'wpc-wall-panel': [
    { name: 'Oak WPC Fluted Panel', value: 38, unit: 'sqm', desc: 'Fluted wood-plastic composite in oak', about: 'Moisture-resistant fluted WPC panel with a warm oak tone — low maintenance and quietly refined.', stock: 64, status: 'active' },
    { name: 'Walnut WPC Fluted Panel', value: 40, unit: 'sqm', desc: 'Fluted WPC panel in deep walnut', about: 'Durable walnut-finish WPC slat panel for elegant vertical lines.', stock: 30, status: 'low' },
  ],
  'pvc-wall-panel': [
    { name: 'Matte White PVC Panel', value: 32, unit: 'sqm', desc: 'Clean matte white wall finish', about: 'Lightweight, easy-to-install PVC panel with a smooth matte finish for fast wall transformations.', stock: 120, status: 'active' },
    { name: 'Stone-Grey PVC Panel', value: 33, unit: 'sqm', desc: 'Subtle stone-grey wall finish', about: 'Versatile grey PVC panel that pairs with both warm and cool palettes.', stock: 12, status: 'low' },
  ],
  'soft-stone': [
    { name: 'Slate Soft Stone Veneer', value: 48, unit: 'sqm', desc: 'Flexible slate-look stone veneer', about: 'Bendable natural stone veneer that wraps curves and columns with authentic slate character.', stock: 96, status: 'active' },
    { name: 'Sandstone Soft Veneer', value: 50, unit: 'sqm', desc: 'Warm sandstone-tone veneer', about: 'Soft sandstone veneer bringing earthy warmth to feature walls.', stock: 40, status: 'active' },
  ],
  'pu-stone': [
    { name: 'Ledgestone PU Panel', value: 45, unit: 'sqm', desc: 'Stacked-stone polyurethane panel', about: 'Lightweight PU stone with realistic stacked-stone texture — the look of rock at a fraction of the weight.', stock: 70, status: 'active' },
    { name: 'Cobble PU Panel', value: 46, unit: 'sqm', desc: 'Rounded cobble-stone PU panel', about: 'Characterful cobble-look PU panel for rustic, tactile surfaces.', stock: 0, status: 'out' },
  ],
  'lights': [
    { name: 'Brass Pendant Light', value: 120, unit: 'unit', badge: 'NEW', desc: 'Warm brass accent pendant', about: 'Curated brass pendant to set the mood over islands, tables, and entryways.', stock: 60, status: 'active' },
    { name: 'LED Cove Strip (warm)', value: 25, unit: 'm', desc: 'Warm-white cove lighting strip', about: 'Soft warm-white LED strip for ceilings, coves, and accent detailing.', stock: 320, status: 'active' },
  ],
  'artificial-grass-carpets': [
    { name: 'Premium Lawn Turf 40mm', value: 22, unit: 'sqm', desc: 'Lush 40mm artificial lawn', about: 'Soft, natural-looking artificial grass for balconies, courtyards, and play areas.', stock: 150, status: 'active' },
    { name: 'Plush Loop Carpet', value: 18, unit: 'sqm', desc: 'Soft loop-pile floor carpet', about: 'Comfortable loop-pile carpet that brings warmth underfoot indoors.', stock: 110, status: 'active' },
  ],
  'steel-profile': [
    { name: 'Brushed Steel Trim 10mm', value: 12, unit: 'm', desc: 'Slim brushed-steel edge trim', about: 'Precision brushed-steel profile for crisp, modern edges and clean transitions.', stock: 200, status: 'active' },
    { name: 'Gold Steel Profile 15mm', value: 16, unit: 'm', desc: 'Champagne-gold decorative profile', about: 'Decorative gold-finish steel profile for luxury detailing and panel framing.', stock: 8, status: 'low' },
  ],
  'blinds': [
    { name: 'Roller Blackout Blind', value: 35, unit: 'unit', desc: 'Made-to-measure blackout roller', about: 'Tailored blackout roller blind balancing privacy, light control, and understated luxury.', stock: 74, status: 'active' },
    { name: 'Sheer Day-Night Blind', value: 48, unit: 'unit', desc: 'Layered sheer day-night blind', about: 'Elegant zebra-style blind that shifts from sheer to private with a gentle pull.', stock: 50, status: 'active' },
  ],
  'block-boards': [
    { name: 'Mahogany Block Board 18mm', value: 40, unit: 'sheet', desc: 'Strong 18mm mahogany core board', about: 'Engineered block board offering strength and a smooth base for premium joinery.', stock: 110, status: 'active' },
    { name: 'Marine Block Board 25mm', value: 52, unit: 'sheet', desc: 'Moisture-resistant 25mm board', about: 'Heavy-duty marine-grade block board for demanding cabinetry and wet areas.', stock: 45, status: 'active' },
  ],
};

const slugify = (s) =>
  s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

async function deleteAllProducts() {
  const snap = await db.collection('products').get();
  if (snap.empty) {
    console.log('No existing products to delete.');
    return;
  }
  // Batch deletes in chunks of 400 (well under the 500 write limit).
  let deleted = 0;
  let batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    n++;
    deleted++;
    if (n === 400) {
      await batch.commit();
      batch = db.batch();
      n = 0;
    }
  }
  if (n > 0) await batch.commit();
  console.log(`Deleted ${deleted} existing product(s).`);
}

async function seedCategories() {
  const batch = db.batch();
  categories.forEach((c, i) => {
    const ref = db.collection('categories').doc(c.slug);
    batch.set(
      ref,
      {
        name: c.name,
        slug: c.slug,
        imageKey: c.imageKey,
        desc: c.desc,
        order: i,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
  await batch.commit();
  console.log(`Seeded ${categories.length} categories.`);
}

async function seedProducts() {
  const batch = db.batch();
  let order = 0;
  let count = 0;
  for (const cat of categories) {
    const items = sampleProducts[cat.slug] ?? [];
    items.forEach((p, idx) => {
      const id = `${cat.slug}-${idx + 1}`;
      const ref = db.collection('products').doc(id);
      batch.set(ref, {
        name: p.name,
        imageKey: slugify(p.name),
        categoryId: cat.slug, // FK to categories/{slug}
        category: cat.name, // denormalised name (current apps filter on this)
        value: p.value,
        unit: p.unit,
        badge: p.badge ?? null,
        desc: p.desc,
        about: p.about,
        stock: p.stock,
        status: p.status,
        order: order++,
        updatedAt: FieldValue.serverTimestamp(),
      });
      count++;
    });
  }
  await batch.commit();
  console.log(`Seeded ${count} products across ${categories.length} categories.`);
}

async function run() {
  await deleteAllProducts();
  await seedCategories();
  await seedProducts();
}

run()
  .then(() => {
    console.log('Catalogue re-seed complete.');
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
