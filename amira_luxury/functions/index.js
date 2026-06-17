// Amira — AI interior render generation (Visual Studio).
//
// Callable function: takes the user's room photo + selected product references
// and asks Gemini's image model to apply those materials into the room, then
// saves the result to Storage and records it under users/{uid}/renders.
//
// The Gemini API key is stored as a Functions secret (GEMINI_API_KEY), never in
// the app or repo. Set it with:
//   firebase functions:secrets:set GEMINI_API_KEY
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { initializeApp } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { GoogleGenAI } from '@google/genai';
import { randomUUID } from 'node:crypto';

initializeApp();

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const IMAGE_MODEL = 'gemini-2.5-flash-image';
// Deploy marker: ensure public invoker binding for the callable.

async function fetchInlineImage(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Fetch failed (${res.status})`);
  const buf = Buffer.from(await res.arrayBuffer());
  const mimeType = res.headers.get('content-type') || 'image/jpeg';
  return { inlineData: { mimeType, data: buf.toString('base64') } };
}

export const generateRender = onCall(
  {
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 120,
    memory: '1GiB',
    region: 'us-central1',
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const {
      roomImageUrl,
      productImageUrls = [],
      materialNames = [],
      prompt = '',
    } = request.data || {};

    if (!roomImageUrl) {
      throw new HttpsError('invalid-argument', 'roomImageUrl is required.');
    }

    try {
      console.log('generateRender:start', {
        products: productImageUrls.length,
        materials: materialNames,
      });

      // Build the multimodal request: room first, then product references.
      const room = await fetchInlineImage(roomImageUrl);
      const products = [];
      for (const url of productImageUrls.slice(0, 5)) {
        try {
          products.push(await fetchInlineImage(url));
        } catch (e) {
          console.warn('skip reference image:', e.message);
        }
      }
      console.log('generateRender:images', {
        room: !!room,
        refs: products.length,
      });

      const names = materialNames.length
        ? ` (${materialNames.join(', ')})`
        : '';
      const instruction =
        'You are an interior design visualiser for Amira Interiors, a luxury ' +
        'East African interiors brand. Edit the FIRST image — the user\'s room ' +
        '— to apply the materials/finishes' + names + ' shown in the following ' +
        'reference images. Preserve the room\'s architecture, perspective, ' +
        'furniture and lighting; only change the relevant surfaces so the ' +
        'result looks photorealistic and refined.' +
        (prompt ? ' User preferences: ' + prompt : '');

      const parts = [{ text: instruction }, room, ...products];

      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
      const response = await ai.models.generateContent({
        model: IMAGE_MODEL,
        contents: [{ role: 'user', parts }],
      });

      const cand = response?.candidates?.[0];
      const partsOut = cand?.content?.parts ?? [];
      console.log('generateRender:response', {
        finishReason: cand?.finishReason,
        partKinds: partsOut.map((p) =>
          p.inlineData ? 'image' : p.text ? 'text' : 'other',
        ),
        promptFeedback: response?.promptFeedback,
      });

      const imgPart = partsOut.find((p) => p.inlineData?.data);
      if (!imgPart) {
        const textOut = partsOut.find((p) => p.text)?.text;
        throw new HttpsError(
          'internal',
          'No image returned' + (textOut ? `: ${textOut}` : '.'),
        );
      }

      // Save the result with a download token so the app can load it by URL.
      const outBuf = Buffer.from(imgPart.inlineData.data, 'base64');
      const contentType = imgPart.inlineData.mimeType || 'image/png';
      const ext = contentType.includes('png') ? 'png' : 'jpg';
      const filePath = `renders/${uid}/result_${Date.now()}.${ext}`;
      const token = randomUUID();
      const bucket = getStorage().bucket();
      await bucket.file(filePath).save(outBuf, {
        metadata: {
          contentType,
          metadata: { firebaseStorageDownloadTokens: token },
        },
      });
      const resultUrl =
        `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
        `${encodeURIComponent(filePath)}?alt=media&token=${token}`;

      await getFirestore()
        .collection('users')
        .doc(uid)
        .collection('renders')
        .add({
          roomImageUrl,
          productImageUrls,
          materialNames,
          prompt,
          resultUrl,
          createdAt: FieldValue.serverTimestamp(),
        });

      console.log('generateRender:done', filePath);
      return { resultUrl };
    } catch (e) {
      console.error('generateRender:failed', e?.message, e?.stack);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError('internal', e?.message || 'Render failed.');
    }
  },
);
