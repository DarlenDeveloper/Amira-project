/**
 * Deletes misategorised products from Firestore + Storage,
 * then re-uploads them with the correct category.
 *
 * Affected:
 *  - self adhesive tiles  → was uploaded as 'PVC Wall Panel'
 *  - 3D PANELS            → was uploaded as 'PU Stone'
 */

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { readFile, readdir } from 'node:fs/promises';
import { join, extname, basename } from 'node:path';
import { randomUUID } from 'node:crypto';

const BUCKET       = 'amira-interiors.firebasestorage.app';
const STORAGE_PREFIX = 'products';
const IMAGE_EXTS   = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const FIXES = [
  {
    folder:        '/home/lancing/Downloads/drive-download-20260707T161636Z-3-001/self adhesive tiles',
    wrongCategory: 'PVC Wall Panel',
    rightCategory: 'Self Adhesive Tiles',
    // These are the storage paths that were wrongly created
    storagePaths:  ['products/pvc_wall_panel'],
    urlMatch:      (url) => url.includes('pvc_wall_panel') && /wpc-6[5-9]|wpc-7[0-3]|pvc_wall_panel%2Fwpc/.test(url),
  },
  {
    folder:        '/home/lancing/Downloads/drive-download-20260707T161636Z-3-001/3D PANELS',
    wrongCategory: 'PU Stone',
    rightCategory: '3D Panels',
    urlMatch:      (url) => url.includes('pu_stone') && /profiles-2[7-9]|profiles-3[0-4]/.test(url),
  },
];

if (!getApps().length) {
  const serviceAccount = JSON.parse(
    await readFile('/home/lancing/Downloads/amira-interiors-firebase-adminsdk-fbsvc-5a76e789ca.json', 'utf8')
  );
  initializeApp({ credential: cert(serviceAccount), storageBucket: BUCKET });
}

const db      = getFirestore();
const storage = getStorage().bucket();

function mimeType(ext) {
  if (ext === '.png')  return 'image/png';
  if (ext === '.webp') return 'image/webp';
  return 'image/jpeg';
}

function slugify(str) {
  return str.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
}

function buildUrl(filePath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(filePath)}?alt=media&token=${token}`;
}

async function getMaxOrder() {
  const snap = await db.collection('products').orderBy('order', 'desc').limit(1).get();
  if (snap.empty) return 0;
  return snap.docs[0].data().order || 0;
}

async function main() {
  const allSnap = await db.collection('products').get();
  let maxOrder = await getMaxOrder();

  for (const fix of FIXES) {
    console.log(`\n── Processing: ${fix.rightCategory} ──`);

    // 1. Find & delete wrong Firestore docs
    const toDelete = allSnap.docs.filter(d => fix.urlMatch(d.data().imageUrl || ''));
    console.log(`Found ${toDelete.length} wrong docs to delete`);

    for (const doc of toDelete) {
      // Delete from Storage
      const url = doc.data().imageUrl || '';
      try {
        const match = decodeURIComponent(url).match(/\/o\/(.+?)\?/);
        if (match) {
          await storage.file(match[1]).delete();
          console.log(`  Deleted storage: ${match[1]}`);
        }
      } catch (e) {
        console.log(`  Storage delete skipped: ${e.message}`);
      }
      // Delete from Firestore
      await doc.ref.delete();
      console.log(`  Deleted doc: ${doc.id}`);
    }

    // 2. Re-upload from the correct folder with correct category
    const entries = await readdir(fix.folder, { withFileTypes: true });
    const images  = entries
      .filter(e => e.isFile() && IMAGE_EXTS.has(extname(e.name).toLowerCase()))
      .map(e => join(fix.folder, e.name));

    console.log(`Re-uploading ${images.length} images as '${fix.rightCategory}'`);

    for (const filePath of images) {
      const ext      = extname(filePath).toLowerCase();
      const name     = basename(filePath, ext)
        .replace(/[-_]/g, ' ')
        .replace(/\b\w/g, c => c.toUpperCase());
      const dest     = `${STORAGE_PREFIX}/${slugify(fix.rightCategory)}/${slugify(basename(filePath, ext))}${ext}`;
      const buffer   = await readFile(filePath);
      const token    = randomUUID();

      process.stdout.write(`  Uploading ${basename(filePath)}... `);

      await storage.file(dest).save(buffer, {
        metadata: {
          contentType: mimeType(ext),
          metadata: { firebaseStorageDownloadTokens: token },
        },
      });

      const imageUrl = buildUrl(dest, token);
      maxOrder++;

      await db.collection('products').add({
        name,
        category:  fix.rightCategory,
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

      console.log('✅');
    }
  }

  console.log('\n── All done ──');
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
