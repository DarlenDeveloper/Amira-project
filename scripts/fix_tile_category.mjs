import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFile } from 'node:fs/promises';

const KEY = '/home/lancing/Downloads/amira-interiors-firebase-adminsdk-fbsvc-5a76e789ca.json';
const BUCKET = 'amira-interiors.firebasestorage.app';

const serviceAccount = JSON.parse(await readFile(KEY, 'utf8'));

if (!getApps().length) {
  initializeApp({ credential: cert(serviceAccount), storageBucket: BUCKET });
}

const db = getFirestore();

async function main() {
  const snap = await db.collection('products').get();

  let fixed = 0;
  const batch = db.batch();

  for (const doc of snap.docs) {
    const url = doc.data().imageUrl || '';

    // Self adhesive tiles: from self adhesive tiles folder (wpc-65 to wpc-73 + wpc.JPG)
    // uploaded under products/pvc_wall_panel/ — slugified: wpc6[5-9]jpg, wpc7[0-3]jpg
    if (url.includes('pvc_wall_panel') && /wpc6[5-9]jpg|wpc7[0-3]jpg/.test(url)) {
      batch.update(doc.ref, { category: 'Self Adhesive Tiles' });
      console.log(`[Tiles]     ${doc.data().name}`);
      fixed++;
    }

    // 3D panels: from 3D PANELS folder (profiles-27 to profiles-34)
    // uploaded under products/pu_stone/ — slugified: profiles2[7-9]jpg, profiles3[0-4]jpg
    if (url.includes('pu_stone') && /profiles2[7-9]jpg|profiles3[0-4]jpg/.test(url)) {
      batch.update(doc.ref, { category: '3D Panels' });
      console.log(`[3D Panels] ${doc.data().name}`);
      fixed++;
    }
  }

  if (fixed === 0) {
    console.log('No matching docs found — check URL patterns.');
    // Print sample URLs to help debug
    const samples = snap.docs.slice(0, 5).map(d => d.data().imageUrl);
    console.log('Sample URLs:', samples);
    return;
  }

  await batch.commit();
  console.log(`\nDone. Fixed ${fixed} products.`);
}

main().catch(e => { console.error(e.message); process.exit(1); });
