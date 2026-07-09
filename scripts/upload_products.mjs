/**
 * Amira — Bulk product image uploader
 *
 * Reads product images from a local folder, uploads each image to Firebase
 * Storage, and creates a product doc in Firestore under `products/`.
 *
 * Usage:
 *   node upload_products.mjs
 *
 * Auth: uses the Firebase CLI session (firebase login --reauth if needed).
 */

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { readdir, readFile, stat } from 'node:fs/promises';
import { join, extname, basename } from 'node:path';
import { execSync } from 'node:child_process';

// ── Config ───────────────────────────────────────────────────────────────────

const IMAGES_ROOT = '/home/lancing/Downloads/drive-download-20260707T161636Z-3-001';
const PROJECT_ID  = 'amira-interiors';
const BUCKET      = 'amira-interiors.firebasestorage.app';
const STORAGE_PREFIX = 'products'; // Storage path: products/{category}/{filename}

// Map folder names → Amira category names (matches what's already in Firestore)
const CATEGORY_MAP = {
  'amira lights':          'Lights',
  'blinds':                'Blinds',
  'blinds options':        'Blinds',
  'flexible wall panels':  'Flexible Wall Panels',
  '3d panels':             'PU Stone',
  'pu stones':             'PU Stone',
  'self adhesive tiles':   'PVC Wall Panel',
  'wpc panels off cuts':   'WPC Wall Panel',
  'grass':                 'Artificial Grass & Carpets',
};

// Supported image extensions
const IMAGE_EXTS = new Set(['.jpg', '.jpeg', '.png', '.webp']);

// ── Firebase init via CLI token ───────────────────────────────────────────────

// Get an access token from the logged-in Firebase CLI session
function getCliToken() {
  try {
    const token = execSync('firebase --token "" projects:list 2>&1 || true').toString();
    // Use application default credentials instead
    return null;
  } catch {
    return null;
  }
}

if (!getApps().length) {
  const serviceAccount = JSON.parse(
    await readFile('/home/lancing/Downloads/amira-interiors-firebase-adminsdk-fbsvc-71ac618ffb.json', 'utf8')
  );
  initializeApp({
    credential: cert(serviceAccount),
    storageBucket: BUCKET,
  });
}

const db      = getFirestore();
const storage = getStorage().bucket();

// ── Helpers ──────────────────────────────────────────────────────────────────

function mimeType(ext) {
  if (ext === '.png')  return 'image/png';
  if (ext === '.webp') return 'image/webp';
  return 'image/jpeg';
}

function slugify(str) {
  return str.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
}

// Recursively collect all image files under a directory
async function collectImages(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      files.push(...await collectImages(full));
    } else if (IMAGE_EXTS.has(extname(e.name).toLowerCase())) {
      files.push(full);
    }
  }
  return files;
}

// Determine category from the top-level folder name under IMAGES_ROOT
function categoryFromPath(filePath) {
  const relative = filePath.replace(IMAGES_ROOT + '/', '');
  const topFolder = relative.split('/')[0].toLowerCase();
  return CATEGORY_MAP[topFolder] || topFolder;
}

// Upload one image to Storage and return its public download URL
async function uploadImage(filePath, category) {
  const ext      = extname(filePath).toLowerCase();
  const name     = basename(filePath, ext);
  const dest     = `${STORAGE_PREFIX}/${slugify(category)}/${slugify(name)}${ext}`;

  const buffer   = await readFile(filePath);
  const file     = storage.file(dest);

  // Skip if already uploaded
  const [exists] = await file.exists();
  if (exists) {
    const [meta] = await file.getMetadata();
    const token  = meta.metadata?.firebaseStorageDownloadTokens;
    if (token) {
      return buildUrl(dest, token);
    }
  }

  const token = crypto.randomUUID();
  await file.save(buffer, {
    metadata: {
      contentType: mimeType(ext),
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });

  return buildUrl(dest, token);
}

function buildUrl(filePath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(filePath)}?alt=media&token=${token}`;
}

// Get the highest existing order value so new products are appended
async function getMaxOrder() {
  const snap = await db.collection('products').orderBy('order', 'desc').limit(1).get();
  if (snap.empty) return 0;
  return (snap.docs[0].data().order || 0);
}

// Check if a product with this imageUrl already exists (avoid duplicates)
async function imageUrlExists(url) {
  const snap = await db.collection('products').where('imageUrl', '==', url).limit(1).get();
  return !snap.empty;
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🔍 Scanning images folder...');
  const allImages = await collectImages(IMAGES_ROOT);
  console.log(`Found ${allImages.length} images across all folders.\n`);

  let maxOrder = await getMaxOrder();
  let uploaded = 0;
  let skipped  = 0;
  let failed   = 0;

  for (const filePath of allImages) {
    const category = categoryFromPath(filePath);
    const name     = basename(filePath, extname(filePath))
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());

    try {
      process.stdout.write(`Uploading: ${basename(filePath)} (${category})... `);

      const imageUrl = await uploadImage(filePath, category);

      // Skip Firestore write if already exists
      if (await imageUrlExists(imageUrl)) {
        console.log('already exists, skipping.');
        skipped++;
        continue;
      }

      maxOrder++;
      await db.collection('products').add({
        name,
        category,
        imageUrl,
        imageKey:  '',
        images:    [imageUrl],
        value:     0,
        unit:      'unit',
        about:     '',
        desc:      '',
        badge:     null,
        stock:     100,
        status:    'active',
        order:     maxOrder,
        colors:    [],
        createdAt: FieldValue.serverTimestamp(),
      });

      console.log('✅ done');
      uploaded++;
    } catch (e) {
      console.log(`❌ failed: ${e.message}`);
      failed++;
    }
  }

  console.log(`\n──────────────────────────────`);
  console.log(`✅ Uploaded : ${uploaded}`);
  console.log(`⏭  Skipped  : ${skipped}`);
  console.log(`❌ Failed   : ${failed}`);
  console.log(`──────────────────────────────`);
}

main().catch(e => {
  console.error('Fatal:', e.message);
  process.exit(1);
});
