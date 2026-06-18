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

// ── Amira AI chat agent ──────────────────────────────────────────────────────
//
// Callable function powering the app's "Amira Agent" screen. Uses a small, fast
// Gemini text model (admin-configurable) with the SAME GEMINI_API_KEY secret as
// the render pipeline. Behaviour (persona, greeting, model, temperature, on/off)
// is controlled from the admin dashboard via the `config/agent` document, so the
// brand can tune the assistant without a redeploy.
//
// The function owns the conversation: it ensures a `conversations/{id}` doc,
// appends the user's message and the agent's reply to the `messages`
// subcollection (the same threads the admin reviews), and returns the reply.
const CHAT_MODEL_DEFAULT = 'gemini-2.5-flash-lite';
const HISTORY_LIMIT = 12; // recent turns sent as context
const CATALOGUE_LIMIT = 40; // products surfaced to the model for grounding

async function loadAgentConfig(dbRef) {
  const snap = await dbRef.collection('config').doc('agent').get();
  const c = snap.exists ? snap.data() : {};
  return {
    enabled: c.enabled !== false, // default on
    persona:
      (c.persona && String(c.persona).trim()) ||
      'You are Amira Agent, the warm, knowledgeable assistant for Amira ' +
        'Interiors — a luxury East African interiors brand. Help customers ' +
        'explore finishes (wall panels, marble, stone, lighting and more), ' +
        'suggest ideas for their space, and guide them toward products and ' +
        'booking a consultation. Be concise, refined and friendly. Prices are ' +
        'in Ugandan shillings (UGX). If unsure, offer to connect them with the ' +
        'Amira team rather than inventing details.',
    model: (c.model && String(c.model).trim()) || CHAT_MODEL_DEFAULT,
    temperature: typeof c.temperature === 'number' ? c.temperature : 0.7,
  };
}

async function loadCatalogueContext(dbRef) {
  try {
    const snap = await dbRef
      .collection('products')
      .orderBy('order')
      .limit(CATALOGUE_LIMIT)
      .get();
    if (snap.empty) return '';
    const lines = snap.docs.map((d) => {
      const p = d.data();
      const price = p.value ? `UGX ${p.value}/${p.unit || 'unit'}` : 'price on request';
      const avail = p.status === 'out' ? ' (out of stock)' : '';
      return `- ${p.name} [${p.category || 'general'}] — ${price}${avail}`;
    });
    return `\n\nCurrent Amira catalogue (for reference, do not list unless relevant):\n${lines.join('\n')}`;
  } catch (e) {
    console.warn('chatAgent: catalogue load failed:', e.message);
    return '';
  }
}

export const chatAgent = onCall(
  {
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 60,
    memory: '512MiB',
    region: 'us-central1',
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const message = String(request.data?.message ?? '').trim();
    if (!message) throw new HttpsError('invalid-argument', 'message is required.');
    let conversationId = request.data?.conversationId || null;

    const db = getFirestore();
    const config = await loadAgentConfig(db);
    if (!config.enabled) {
      throw new HttpsError(
        'failed-precondition',
        'The Amira Agent is currently unavailable. Please try again later.',
      );
    }

    // Resolve the customer's display details for the conversation header.
    let customer = 'Amira Member';
    let email = '';
    try {
      const userSnap = await db.collection('users').doc(uid).get();
      const u = userSnap.exists ? userSnap.data() : {};
      customer = (u.name && u.name.trim()) || customer;
      email = u.email || u.phone || '';
    } catch (e) {
      console.warn('chatAgent: user lookup failed:', e.message);
    }

    // Ensure the conversation document exists (create on first message).
    const conversations = db.collection('conversations');
    let convRef;
    if (conversationId) {
      convRef = conversations.doc(conversationId);
    } else {
      convRef = await conversations.add({
        uid,
        customer,
        email,
        status: 'open',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      conversationId = convRef.id;
    }
    const messagesRef = convRef.collection('messages');

    // Persist the user's message first.
    await messagesRef.add({
      from: 'user',
      text: message,
      time: FieldValue.serverTimestamp(),
    });

    // Build context: recent history (oldest→newest) + the new message.
    let history = [];
    try {
      const histSnap = await messagesRef.orderBy('time', 'desc').limit(HISTORY_LIMIT).get();
      history = histSnap.docs
        .map((d) => d.data())
        .reverse()
        .map((m) => ({
          role: m.from === 'user' ? 'user' : 'model',
          parts: [{ text: String(m.text ?? '') }],
        }));
    } catch (e) {
      console.warn('chatAgent: history load failed:', e.message);
      history = [{ role: 'user', parts: [{ text: message }] }];
    }

    const catalogue = await loadCatalogueContext(db);
    const systemInstruction = config.persona + catalogue;

    let reply;
    try {
      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
      const response = await ai.models.generateContent({
        model: config.model,
        contents: history,
        config: {
          temperature: config.temperature,
          systemInstruction,
          maxOutputTokens: 600,
        },
      });
      reply = (response?.text ?? '').trim();
    } catch (e) {
      console.error('chatAgent: generation failed:', e?.message);
      throw new HttpsError('internal', 'The agent could not respond right now.');
    }

    if (!reply) {
      reply = "I'm sorry, I didn't quite catch that. Could you rephrase?";
    }

    // Persist the agent's reply and bump the thread (with a denormalised preview
    // so the admin can show recent activity without a collection-group query).
    await messagesRef.add({
      from: 'agent',
      text: reply,
      time: FieldValue.serverTimestamp(),
    });
    await convRef.set(
      {
        lastMessage: reply,
        lastFrom: 'agent',
        lastUserMessage: message,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { conversationId, reply };
  },
);
