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
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { GoogleGenAI } from '@google/genai';
import { createHash, randomInt, randomUUID } from 'node:crypto';

initializeApp();

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');
const IMAGE_MODEL = 'gemini-2.5-flash-image';
const RENDER_SESSION_TTL_MS = 2 * 60 * 60 * 1000; // 2 hours
const RENDER_RATE_LIMIT = 0; // renders allowed per user per rolling hour (0 = disabled)
const RENDER_RATE_WINDOW_MS = 60 * 60 * 1000; // …per rolling hour

// Rolling-window rate limit stored as a timestamp list under
// renderRateLimits/{uid}. Avoids a composite index on the renders collection.
async function getRecentRenderCount(db, uid) {
  const snap = await db.collection('renderRateLimits').doc(uid).get();
  if (!snap.exists) return 0;
  const hits = Array.isArray(snap.data().hits) ? snap.data().hits : [];
  const windowStart = Date.now() - RENDER_RATE_WINDOW_MS;
  return hits.filter((t) => typeof t === 'number' && t > windowStart).length;
}

async function recordRenderHit(db, uid) {
  const ref = db.collection('renderRateLimits').doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const hits =
      snap.exists && Array.isArray(snap.data().hits) ? snap.data().hits : [];
    const windowStart = Date.now() - RENDER_RATE_WINDOW_MS;
    const recent = hits.filter((t) => typeof t === 'number' && t > windowStart);
    recent.push(Date.now());
    tx.set(
      ref,
      { hits: recent, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

function assertUnderRenderLimit(count) {
  if (RENDER_RATE_LIMIT <= 0) return; // rate limiting disabled
  if (count >= RENDER_RATE_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      `You've reached the limit of ${RENDER_RATE_LIMIT} renders per hour. Please try again later.`,
    );
  }
}

// Builds the image-model instruction. Applies EVERY reference item (not just
// one surface), and handles both flat surface finishes and physical products
// such as lights or blinds so multi-material renders include all selections.
function buildRenderInstruction(materialNames, prompt) {
  const names = materialNames.length ? ` (${materialNames.join(', ')})` : '';
  return (
    'Use the FIRST image as the exact base scene: a real photograph of the ' +
    "user's room. Apply ALL of the reference items" + names + ' shown in the ' +
    'other image(s) into this one room in a single cohesive result — do not ' +
    'skip any of them. For each reference, decide what it is and place it ' +
    'correctly:\n' +
    '- Flat surface materials (wall panels, marble, stone, wallpaper, tiles, ' +
    'flooring, artificial grass and similar) are texture and colour swatches: ' +
    'apply them as a realistic finish on the surface they naturally belong to ' +
    '(wall finishes lie flat on the relevant wall, flooring on the floor). Do ' +
    'NOT insert these as objects, framed pictures, panels, partitions or ' +
    'freestanding pieces, and never lay a wall material across the floor or ' +
    'ceiling.\n' +
    '- Physical products (lights and light fixtures, blinds, furniture and ' +
    'similar) are real objects: install each one naturally in the room at a ' +
    'realistic position, scale and orientation (for example a pendant light ' +
    'hangs from the ceiling, blinds mount on the window).\n' +
    'Keep the rest of the room identical to the original photograph — the same ' +
    'camera angle, framing and proportions, and every surface, fixture, ' +
    'furniture and decor item that is not being changed. The result must be ' +
    'photorealistic and lit to match the original scene.' +
    (prompt ? ' User preferences: ' + prompt : '')
  );
}

async function fetchInlineImage(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Fetch failed (${res.status})`);
  const buf = Buffer.from(await res.arrayBuffer());
  const mimeType = res.headers.get('content-type') || 'image/jpeg';
  return { inlineData: { mimeType, data: buf.toString('base64') } };
}

async function resolveUserProfile(db, uid) {
  let customer = 'Amira Member';
  let email = '';
  let phone = '';
  try {
    const userSnap = await db.collection('users').doc(uid).get();
    const u = userSnap.exists ? userSnap.data() : {};
    phone = (u.phone && String(u.phone).trim()) || '';
    const rawEmail = (u.email && String(u.email).trim()) || '';
    email = rawEmail.includes('@phone.amira.app') ? '' : rawEmail;
    const name = (u.name && String(u.name).trim()) || '';
    customer = name || phone || (email ? email.split('@')[0] : '') || customer;
  } catch (e) {
    console.warn('user lookup failed:', e.message);
  }
  return { customer, email, phone };
}

function buildDownloadUrl(bucket, filePath, token) {
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
    `${encodeURIComponent(filePath)}?alt=media&token=${token}`
  );
}

async function mirrorRenderDoc(db, renderId, data) {
  const uid = data.uid;
  if (!uid) return;
  await db
    .collection('users')
    .doc(uid)
    .collection('renders')
    .doc(renderId)
    .set(data, { merge: true });
}

async function setRenderDoc(db, renderId, patch) {
  const ref = db.collection('renders').doc(renderId);
  await ref.set({ ...patch, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  const snap = await ref.get();
  if (snap.exists) {
    await mirrorRenderDoc(db, renderId, { id: renderId, ...snap.data() });
  }
}

// ── Visual Studio session lifecycle ──────────────────────────────────────────

export const startRenderSession = onCall(
  { region: 'us-central1' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const {
      productIds = [],
      materialNames = [],
      source = 'tab',
      prompt = '',
    } = request.data || {};

    const db = getFirestore();
    const { customer, email, phone } = await resolveUserProfile(db, uid);
    const renderRef = db.collection('renders').doc();
    const renderId = renderRef.id;
    const expiresAt = new Date(Date.now() + RENDER_SESSION_TTL_MS);

    const doc = {
      renderId,
      uid,
      customer,
      email,
      status: 'uploading',
      source: String(source || 'tab'),
      productIds: Array.isArray(productIds) ? productIds.slice(0, 5) : [],
      materialNames: Array.isArray(materialNames) ? materialNames.slice(0, 5) : [],
      prompt: String(prompt || ''),
      model: IMAGE_MODEL,
      expiresAt,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await renderRef.set(doc);
    await mirrorRenderDoc(db, renderId, doc);

    return { renderId };
  },
);

export const registerRoomUpload = onCall(
  { region: 'us-central1' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const renderId = String(request.data?.renderId ?? '').trim();
    const roomImageUrl = String(request.data?.roomImageUrl ?? '').trim();
    if (!renderId || !roomImageUrl) {
      throw new HttpsError('invalid-argument', 'renderId and roomImageUrl are required.');
    }

    const db = getFirestore();
    const ref = db.collection('renders').doc(renderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Render session not found.');
    }
    const data = snap.data();
    if (data.uid !== uid) {
      throw new HttpsError('permission-denied', 'Not your render session.');
    }
    if (data.status !== 'uploading') {
      throw new HttpsError(
        'failed-precondition',
        `Cannot register upload while status is "${data.status}".`,
      );
    }

    const roomStoragePath = `visual-studio/${uid}/${renderId}/room.jpg`;
    await setRenderDoc(db, renderId, {
      status: 'ready',
      roomStoragePath,
      roomImageUrl,
    });

    return { ok: true };
  },
);

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
      roomImageUrl: roomImageUrlIn,
      productImageUrls: legacyProductUrls = [],
      materialNames: legacyMaterialNames = [],
      prompt: legacyPrompt = '',
    } = request.data || {};
    const renderId = String(request.data?.renderId ?? '').trim();
    const forceRetry = request.data?.forceRetry === true;

    // Legacy Play Store clients (no renderId) — keep old request shape working.
    if (!renderId) {
      const roomImageUrl = String(roomImageUrlIn ?? '').trim();
      if (!roomImageUrl) {
        throw new HttpsError('invalid-argument', 'renderId or roomImageUrl is required.');
      }
      return runLegacyGenerateRender(uid, {
        roomImageUrl,
        productImageUrls: legacyProductUrls,
        materialNames: legacyMaterialNames,
        prompt: legacyPrompt,
      });
    }

    const db = getFirestore();
    const ref = db.collection('renders').doc(renderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Render session not found.');
    }
    const data = snap.data();
    if (data.uid !== uid) {
      throw new HttpsError('permission-denied', 'Not your render session.');
    }

    if (data.status === 'completed' && data.resultUrl && !forceRetry) {
      return { resultUrl: data.resultUrl, renderId };
    }
    if (data.status === 'generating') {
      throw new HttpsError(
        'failed-precondition',
        'A render is already in progress for this session.',
      );
    }
    if (data.status === 'uploading') {
      throw new HttpsError(
        'failed-precondition',
        'Room photo has not been uploaded yet.',
      );
    }
    if (data.status === 'failed' && !forceRetry) {
      throw new HttpsError(
        'failed-precondition',
        'This session failed. Pass forceRetry to try again.',
      );
    }
    if (
      data.status !== 'ready' &&
      !(data.status === 'failed' && forceRetry) &&
      !(data.status === 'completed' && forceRetry)
    ) {
      throw new HttpsError(
        'failed-precondition',
        `Cannot generate while status is "${data.status}".`,
      );
    }

    const roomImageUrl = data.roomImageUrl;
    if (!roomImageUrl) {
      throw new HttpsError('failed-precondition', 'No room image on this session.');
    }

    // Rate limit: at most RENDER_RATE_LIMIT renders per rolling hour per user.
    assertUnderRenderLimit(await getRecentRenderCount(db, uid));

    // Latest selection from the client wins (materials/prompt are decoupled
    // from session creation, so a user can pick the photo first then choose
    // finishes). Fall back to whatever was stored on the session.
    const reqProductIds = Array.isArray(request.data?.productIds)
      ? request.data.productIds.filter((x) => typeof x === 'string').slice(0, 5)
      : null;
    const reqMaterialNames = Array.isArray(request.data?.materialNames)
      ? request.data.materialNames.filter((x) => typeof x === 'string').slice(0, 5)
      : null;
    const reqPrompt =
      typeof request.data?.prompt === 'string' ? request.data.prompt : null;

    const productIds = reqProductIds ?? (data.productIds || []);
    const materialNames = reqMaterialNames ?? (data.materialNames || []);
    const prompt = reqPrompt ?? (data.prompt || '');

    // Persist the latest selection so the saved render reflects what was used.
    if (reqProductIds || reqMaterialNames || reqPrompt !== null) {
      await setRenderDoc(db, renderId, {
        ...(reqProductIds ? { productIds } : {}),
        ...(reqMaterialNames ? { materialNames } : {}),
        ...(reqPrompt !== null ? { prompt } : {}),
      });
    }

    // Atomically claim the session.
    try {
      await db.runTransaction(async (tx) => {
        const fresh = await tx.get(ref);
        if (!fresh.exists) throw new HttpsError('not-found', 'Render session not found.');
        const s = fresh.data().status;
        if (s === 'completed' && !forceRetry) return;
        if (s === 'generating') {
          throw new HttpsError('failed-precondition', 'Render already in progress.');
        }
        if (
          s !== 'ready' &&
          !(s === 'failed' && forceRetry) &&
          !(s === 'completed' && forceRetry)
        ) {
          throw new HttpsError('failed-precondition', `Invalid status "${s}".`);
        }
        tx.set(
          ref,
          { status: 'generating', updatedAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      throw e;
    }

    // Re-check after transaction (another caller may have completed).
    const afterClaim = (await ref.get()).data();
    if (afterClaim.status === 'completed' && afterClaim.resultUrl && !forceRetry) {
      return { resultUrl: afterClaim.resultUrl, renderId };
    }

    // Load product image URLs from catalogue when productIds present.
    let productImageUrls = [];
    if (productIds.length) {
      for (const pid of productIds.slice(0, 5)) {
        try {
          const pSnap = await db.collection('products').doc(pid).get();
          if (pSnap.exists) {
            const url = pSnap.data().imageUrl;
            if (url) productImageUrls.push(url);
          }
        } catch (e) {
          console.warn('skip product image:', pid, e.message);
        }
      }
    }

    try {
      console.log('generateRender:start', { renderId, products: productImageUrls.length });

      const room = await fetchInlineImage(roomImageUrl);
      const products = [];
      for (const url of productImageUrls.slice(0, 5)) {
        try {
          products.push(await fetchInlineImage(url));
        } catch (e) {
          console.warn('skip reference image:', e.message);
        }
      }

      const instruction = buildRenderInstruction(materialNames, prompt);

      const parts = [{ text: instruction }, room, ...products];
      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
      const response = await ai.models.generateContent({
        model: IMAGE_MODEL,
        contents: [{ role: 'user', parts }],
        config: { temperature: 0.1 },
      });

      const cand = response?.candidates?.[0];
      const partsOut = cand?.content?.parts ?? [];
      const imgPart = partsOut.find((p) => p.inlineData?.data);
      if (!imgPart) {
        const textOut = partsOut.find((p) => p.text)?.text;
        throw new HttpsError(
          'internal',
          'No image returned' + (textOut ? `: ${textOut}` : '.'),
        );
      }

      const outBuf = Buffer.from(imgPart.inlineData.data, 'base64');
      const contentType = imgPart.inlineData.mimeType || 'image/png';
      const ext = contentType.includes('png') ? 'png' : 'jpg';
      const resultStoragePath = `visual-studio/${uid}/${renderId}/result.${ext}`;
      const token = randomUUID();
      const bucket = getStorage().bucket();
      await bucket.file(resultStoragePath).save(outBuf, {
        metadata: {
          contentType,
          metadata: { firebaseStorageDownloadTokens: token },
        },
      });
      const resultUrl = buildDownloadUrl(bucket, resultStoragePath, token);

      await setRenderDoc(db, renderId, {
        status: 'completed',
        resultStoragePath,
        resultUrl,
        productImageUrls,
        error: FieldValue.delete(),
        completedAt: FieldValue.serverTimestamp(),
      });

      console.log('generateRender:done', resultStoragePath);
      await recordRenderHit(db, uid);
      return { resultUrl, renderId };
    } catch (e) {
      console.error('generateRender:failed', e?.message, e?.stack);
      const errMsg = e?.message || 'Render failed.';
      await setRenderDoc(db, renderId, {
        status: 'failed',
        error: errMsg,
      });
      if (e instanceof HttpsError) throw e;
      throw new HttpsError('internal', errMsg);
    }
  },
);

/** Play Store builds that call generateRender with roomImageUrl only (no session). */
async function runLegacyGenerateRender(uid, {
  roomImageUrl,
  productImageUrls = [],
  materialNames = [],
  prompt = '',
}) {
  const db = getFirestore();
  assertUnderRenderLimit(await getRecentRenderCount(db, uid));
  try {
    const room = await fetchInlineImage(roomImageUrl);
    const products = [];
    for (const url of productImageUrls.slice(0, 5)) {
      try {
        products.push(await fetchInlineImage(url));
      } catch (e) {
        console.warn('legacy skip reference image:', e.message);
      }
    }
    const instruction = buildRenderInstruction(materialNames, prompt);
    const parts = [{ text: instruction }, room, ...products];
    const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
    const response = await ai.models.generateContent({
      model: IMAGE_MODEL,
      contents: [{ role: 'user', parts }],
      config: { temperature: 0.1 },
    });
    const imgPart = response?.candidates?.[0]?.content?.parts?.find((p) => p.inlineData?.data);
    if (!imgPart) {
      throw new HttpsError('internal', 'No image returned.');
    }
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
    const resultUrl = buildDownloadUrl(bucket, filePath, token);
    await db
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
    await recordRenderHit(db, uid);
    return { resultUrl };
  } catch (e) {
    console.error('generateRender:legacy failed', e?.message);
    if (e instanceof HttpsError) throw e;
    throw new HttpsError('internal', e?.message || 'Render failed.');
  }
}

export const cleanupStaleRenders = onSchedule(
  { schedule: 'every 24 hours', region: 'us-central1' },
  async () => {
    const db = getFirestore();
    const now = new Date();
    const staleStatuses = ['uploading', 'ready', 'generating'];
    for (const status of staleStatuses) {
      const snap = await db
        .collection('renders')
        .where('status', '==', status)
        .where('expiresAt', '<', now)
        .limit(200)
        .get();
      for (const doc of snap.docs) {
        const msg =
          status === 'uploading'
            ? 'Session timed out before upload completed'
            : status === 'ready'
              ? 'Session timed out before generation started'
              : 'Session timed out during generation';
        await setRenderDoc(db, doc.id, {
          status: 'failed',
          error: msg,
        });
      }
      console.log('cleanupStaleRenders', status, snap.size);
    }
  },
);

// ── Prompt enhancer ──────────────────────────────────────────────────────────
//
// Turns a user's rough description (and chosen finishes) into a richer, vivid
// interior-design prompt for the render. Reuses the GEMINI_API_KEY secret and a
// small/fast text model.
export const enhancePrompt = onCall(
  {
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 30,
    memory: '256MiB',
    region: 'us-central1',
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const raw = String(request.data?.prompt ?? '').trim().slice(0, 600);
    const materialNames = Array.isArray(request.data?.materialNames)
      ? request.data.materialNames
          .filter((x) => typeof x === 'string')
          .slice(0, 5)
      : [];
    if (!raw && !materialNames.length) {
      throw new HttpsError(
        'invalid-argument',
        'Add a short description or pick a material first.',
      );
    }

    const materialsLine = materialNames.length
      ? ` The user has chosen these Amira finishes: ${materialNames.join(', ')}.`
      : '';
    const systemInstruction =
      'You refine a user\'s short interior-design request into a clear, ' +
      'render-ready prompt for an AI room visualiser. Keep the user\'s intent ' +
      'exactly as written; expand it into 1-2 concise, concrete sentences ' +
      'describing what to add or change and a fitting style. Do not invent ' +
      'unrelated changes. Return ONLY the prompt text — no preamble, quotes ' +
      'or labels.' + materialsLine;

    try {
      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
      const response = await ai.models.generateContent({
        model: CHAT_MODEL_DEFAULT,
        contents: [
          {
            role: 'user',
            parts: [
              {
                text:
                  'Rough idea: ' +
                  (raw || '(none — infer a tasteful look from the chosen finishes)'),
              },
            ],
          },
        ],
        config: {
          temperature: 0.7,
          systemInstruction,
          maxOutputTokens: 256,
          // Gemini 2.5 spends "thinking" tokens from the output budget; with a
          // small cap that can leave no room for the actual answer (empty text,
          // finishReason MAX_TOKENS). Disable thinking for this simple rewrite.
          thinkingConfig: { thinkingBudget: 0 },
        },
      });
      const enhanced = (response?.text ?? '').trim();
      if (!enhanced) {
        const finishReason = response?.candidates?.[0]?.finishReason;
        const blockReason = response?.promptFeedback?.blockReason;
        console.error('enhancePrompt: empty result', { finishReason, blockReason });
        throw new HttpsError(
          'internal',
          `Could not enhance the prompt${finishReason ? ` (${finishReason})` : ''}.`,
        );
      }
      return { prompt: enhanced };
    } catch (e) {
      console.error('enhancePrompt failed:', e?.message);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError('internal', e?.message || 'Could not enhance the prompt.');
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
    timeoutSeconds: 120,
    memory: '512MiB',
    region: 'us-central1',
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const message = String(request.data?.message ?? '').trim();
    const imageUrl = request.data?.imageUrl
      ? String(request.data.imageUrl).trim()
      : null;
    if (!message && !imageUrl) {
      throw new HttpsError('invalid-argument', 'message or image is required.');
    }
    let conversationId = request.data?.conversationId || null;
    const productId = request.data?.productId
      ? String(request.data.productId).trim()
      : null;
    const source = String(request.data?.source || 'typed');
    const suggestionLabel = request.data?.suggestionLabel
      ? String(request.data.suggestionLabel).trim()
      : null;

    const db = getFirestore();
    const config = await loadAgentConfig(db);

    const { customer, email, phone } = await resolveUserProfile(db, uid);

    // Ensure the conversation document exists (create on first message).
    const conversations = db.collection('conversations');
    let convRef;
    let isNewConvo = false;
    if (conversationId) {
      convRef = conversations.doc(conversationId);
    } else {
      isNewConvo = true;
      convRef = conversations.doc();
      conversationId = convRef.id;
    }
    const messagesRef = convRef.collection('messages');

    if (isNewConvo) {
      await convRef.set({
        uid,
        customer,
        email,
        phone,
        status: 'open',
        source,
        mode: 'agent',
        messageCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // If an admin has taken over this thread, the AI stays out of it. Persist
    // the customer's message so the admin sees it, bump the thread summary, and
    // return without generating a reply — the human handles it from here.
    if (!isNewConvo) {
      let convoMode = 'agent';
      try {
        const cur = await convRef.get();
        if (cur.exists) convoMode = cur.data().mode || 'agent';
      } catch (e) {
        console.warn('chatAgent: mode lookup failed:', e.message);
      }
      if (convoMode === 'human') {
        await messagesRef.add({
          from: 'user',
          text: message,
          source,
          productId: productId || null,
          suggestionLabel,
          imageUrl: imageUrl || null,
          status: 'sent',
          time: FieldValue.serverTimestamp(),
        });
        await convRef.set(
          {
            lastMessage: message || (imageUrl ? '📷 Photo' : ''),
            lastFrom: 'user',
            messageCount: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return { conversationId, reply: '', mode: 'human' };
      }
    }

    if (!config.enabled) {
      const errText =
        'The Amira Agent is currently unavailable. Please try again later.';
      await messagesRef.add({
        from: 'user',
        text: message,
        source,
        productId: productId || null,
        suggestionLabel,
        status: 'sent',
        time: FieldValue.serverTimestamp(),
      });
      await messagesRef.add({
        from: 'system',
        text: errText,
        status: 'error',
        error: 'agent_disabled',
        time: FieldValue.serverTimestamp(),
      });
      await convRef.set(
        {
          lastMessage: errText,
          lastFrom: 'system',
          messageCount: FieldValue.increment(2),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      throw new HttpsError('failed-precondition', errText);
    }

    // Resolve product context for conversation header.
    let productName = null;
    if (productId) {
      try {
        const pSnap = await db.collection('products').doc(productId).get();
        if (pSnap.exists) productName = pSnap.data().name || null;
      } catch (e) {
        console.warn('chatAgent: product lookup failed:', e.message);
      }
    }

    // Persist the user's message first.
    await messagesRef.add({
      from: 'user',
      text: message,
      source,
      productId: productId || null,
      suggestionLabel,
      imageUrl: imageUrl || null,
      status: 'sent',
      time: FieldValue.serverTimestamp(),
    });

    // Build context: recent history (oldest→newest) + the new message.
    let history = [];
    try {
      const histSnap = await messagesRef.orderBy('time', 'desc').limit(HISTORY_LIMIT).get();
      history = histSnap.docs
        .map((d) => d.data())
        .reverse()
        .filter((m) => m.from === 'user' || m.from === 'agent')
        .map((m) => ({
          role: m.from === 'user' ? 'user' : 'model',
          parts: [{ text: String(m.text ?? '') }],
        }));
    } catch (e) {
      console.warn('chatAgent: history load failed:', e.message);
      history = [{ role: 'user', parts: [{ text: message }] }];
    }

    // Attach the uploaded image (if any) to the most recent user turn so the
    // model can see the room photo. Add a default prompt if no text was typed.
    if (imageUrl) {
      try {
        const img = await fetchInlineImage(imageUrl);
        for (let i = history.length - 1; i >= 0; i--) {
          if (history[i].role === 'user') {
            if (!history[i].parts[0] || !history[i].parts[0].text) {
              history[i].parts[0] = {
                text: 'Please look at this room photo and help me.',
              };
            }
            history[i].parts.push(img);
            break;
          }
        }
      } catch (e) {
        console.warn('chatAgent: image fetch failed:', e.message);
      }
    }

    let catalogue = await loadCatalogueContext(db);
    if (productId && productName) {
      catalogue += `\n\nThe user is asking about product: ${productName} (id: ${productId}).`;
    }
    const systemInstruction = config.persona + catalogue;

    let reply;
    // Vision turns need a multimodal model regardless of the admin's text model.
    let modelUsed = imageUrl ? 'gemini-2.5-flash' : config.model;
    try {
      const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
      const response = await ai.models.generateContent({
        model: modelUsed,
        contents: history,
        config: {
          temperature: config.temperature,
          systemInstruction,
          maxOutputTokens: 800,
          // Gemini 2.5 spends "thinking" tokens from the output budget, which
          // truncates replies mid-sentence. Disable it for chat responses.
          thinkingConfig: { thinkingBudget: 0 },
        },
      });
      reply = (response?.text ?? '').trim();
    } catch (e) {
      console.error('chatAgent: generation failed:', e?.message);
      const errText = 'The agent could not respond right now.';
      await messagesRef.add({
        from: 'agent',
        text: errText,
        model: modelUsed,
        status: 'error',
        error: e?.message || 'generation_failed',
        time: FieldValue.serverTimestamp(),
      });
      await convRef.set(
        {
          lastMessage: errText,
          lastFrom: 'agent',
          messageCount: FieldValue.increment(2),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      throw new HttpsError('internal', errText);
    }

    if (!reply) {
      reply = "I'm sorry, I didn't quite catch that. Could you rephrase?";
    }

    await messagesRef.add({
      from: 'agent',
      text: reply,
      model: modelUsed,
      status: 'sent',
      time: FieldValue.serverTimestamp(),
    });
    await convRef.set(
      {
        customer,
        email,
        phone,
        productId: productId || FieldValue.delete(),
        productName: productName || FieldValue.delete(),
        lastMessage: reply,
        lastFrom: 'agent',
        lastUserMessage: message,
        messageCount: FieldValue.increment(2),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { conversationId, reply };
  },
);

// ── Password reset (email OTP + phone-verified reset) ────────────────────────
//
// Email: requestPasswordResetOtp emails a 6-digit code (Resend). resetPasswordWithOtp
// verifies the code and sets a new password via the Admin SDK.
//
// Phone: the web client verifies SMS OTP with Firebase Phone Auth, then calls
// resetPasswordAfterPhoneVerification while signed in with that phone session.
const PHONE_EMAIL_DOMAIN = 'phone.amira.app';
const OTP_TTL_MS = 10 * 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;

function emailDocId(email) {
  return createHash('sha256').update(email.trim().toLowerCase()).digest('hex');
}

function hashOtp(email, code) {
  return createHash('sha256')
    .update(`${email.trim().toLowerCase()}:${code}`)
    .digest('hex');
}

function phoneToCredentialEmail(phoneE164) {
  const digits = String(phoneE164).replace(/\D/g, '');
  return `${digits}@${PHONE_EMAIL_DOMAIN}`;
}

async function sendOtpEmail(to, code, resendKey) {
  const apiKey = resendKey || process.env.RESEND_API_KEY;
  if (!apiKey) {
    console.warn('[Amira] RESEND_API_KEY not set — OTP for', to, ':', code);
    if (process.env.FUNCTIONS_EMULATOR !== 'true') {
      throw new HttpsError(
        'failed-precondition',
        'Email OTP is not configured. Try resetting with your phone number.',
      );
    }
    return;
  }
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'Amira Luxury <onboarding@resend.dev>',
      to: [to],
      subject: 'Your Amira password reset code',
      html:
        `<p>Your password reset code is:</p>` +
        `<p style="font-size:28px;font-weight:700;letter-spacing:4px">${code}</p>` +
        `<p>This code expires in 10 minutes. If you didn't request this, you can ignore this email.</p>`,
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    console.error('[Amira] Resend failed:', res.status, body);
    throw new HttpsError('internal', 'Could not send the reset code. Please try again.');
  }
}

export const requestPasswordResetOtp = onCall(
  { secrets: [RESEND_API_KEY], region: 'us-central1' },
  async (request) => {
    const email = String(request.data?.email || '').trim().toLowerCase();
    if (!email || !email.includes('@')) {
      throw new HttpsError('invalid-argument', 'A valid email is required.');
    }

    // Always respond the same way so we don't leak which emails exist.
    const generic = { sent: true };

    let uid;
    try {
      const user = await getAuth().getUserByEmail(email);
      uid = user.uid;
      if (user.email?.endsWith(`@${PHONE_EMAIL_DOMAIN}`)) {
        throw new HttpsError(
          'failed-precondition',
          'This account uses a phone number. Reset with your phone instead.',
        );
      }
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      return generic;
    }

    const code = String(randomInt(100000, 999999));
    const db = getFirestore();
    await db.collection('password_reset_otps').doc(emailDocId(email)).set({
      uid,
      email,
      codeHash: hashOtp(email, code),
      expiresAt: Date.now() + OTP_TTL_MS,
      attempts: 0,
      createdAt: FieldValue.serverTimestamp(),
    });

    try {
      await sendOtpEmail(email, code, RESEND_API_KEY.value());
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', 'Could not send the reset code.');
    }

    if (process.env.FUNCTIONS_EMULATOR === 'true') {
      return { ...generic, devOtp: code };
    }
    return generic;
  },
);

export const resetPasswordWithOtp = onCall(
  { region: 'us-central1' },
  async (request) => {
    const email = String(request.data?.email || '').trim().toLowerCase();
    const code = String(request.data?.code || '').trim();
    const newPassword = String(request.data?.newPassword || '');

    if (!email || !code || code.length !== 6) {
      throw new HttpsError('invalid-argument', 'Email and 6-digit code are required.');
    }
    if (newPassword.length < 6) {
      throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }

    const db = getFirestore();
    const ref = db.collection('password_reset_otps').doc(emailDocId(email));
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError('not-found', 'That code has expired. Request a new one.');
    }

    const data = snap.data();
    if (Date.now() > data.expiresAt) {
      await ref.delete();
      throw new HttpsError('deadline-exceeded', 'That code has expired. Request a new one.');
    }
    if (data.attempts >= MAX_OTP_ATTEMPTS) {
      await ref.delete();
      throw new HttpsError('resource-exhausted', 'Too many attempts. Request a new code.');
    }

    if (data.codeHash !== hashOtp(email, code)) {
      await ref.update({ attempts: (data.attempts || 0) + 1 });
      throw new HttpsError('invalid-argument', 'That code is incorrect.');
    }

    await getAuth().updateUser(data.uid, { password: newPassword });
    await ref.delete();
    return { success: true };
  },
);

export const resetPasswordAfterPhoneVerification = onCall(
  { region: 'us-central1' },
  async (request) => {
    const uid = request.auth?.uid;
    const phone = request.auth?.token?.phone_number;
    const newPassword = String(request.data?.newPassword || '');

    if (!uid || !phone) {
      throw new HttpsError('unauthenticated', 'Verify your phone with the SMS code first.');
    }
    if (newPassword.length < 6) {
      throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }

    const credentialEmail = phoneToCredentialEmail(phone);
    let targetUid = uid;
    try {
      const mapped = await getAuth().getUserByEmail(credentialEmail);
      targetUid = mapped.uid;
    } catch {
      // Phone-auth uid may already be the account if providers are linked.
      targetUid = uid;
    }

    await getAuth().updateUser(targetUid, { password: newPassword });
    return { success: true };
  },
);
