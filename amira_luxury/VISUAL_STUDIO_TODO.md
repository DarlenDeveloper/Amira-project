# Visual Studio — UX Work

Tracking the UX improvements to the Visual Studio (AI render) page.

## Done
- [x] **Auto-upload** — picking a photo (camera/gallery) now uploads immediately in the background; no manual "Upload" step. Button shows `Uploading…` → `Visualise with AI`, and falls back to `Upload` on failure.
  - `lib/screens/visual_studio_screen.dart` (`_pickFrom` triggers `_upload()`).
- [x] **Decouple materials/prompt from session** — `generateRender` accepts the latest `productIds` / `materialNames` / `prompt` and refreshes the session before rendering, so selections made *after* upload are used. Also persisted to the saved render.
  - `functions/index.js` (`generateRender`), `lib/services/render_service.dart` (`generateRender` signature), `lib/screens/visual_studio_screen.dart` (`_generate` passes current selection).
- [x] **Deployed** `generateRender` to `amira-interiors` (us-central1).

## Awaiting test (coded, not yet committed/deployed)
- [~] **Prompt enhancer** — "Enhance with AI" button under the description field turns a rough idea (+ chosen finish) into a richer prompt. New `enhancePrompt` Cloud Function (Gemini text model, reuses `GEMINI_API_KEY`).
  - `functions/index.js` (`enhancePrompt`), `lib/services/render_service.dart` (`enhancePrompt`), `lib/screens/visual_studio_screen.dart` (button + `_enhancePrompt`). **Needs deploy.**
- [~] **Rate limit** — 3 renders per user per rolling hour, enforced in `generateRender` (and legacy path) via `renderRateLimits/{uid}` timestamp list; throws `resource-exhausted`. **Needs deploy.**
- [~] **One material at a time** — picking a finish replaces the current one (picker + shell intent). Copy updated to singular. Client-only.
- [~] **ChatGPT-style loading** — replaced the spinner card with a warm shimmer sweep (`_ShimmerLoading`) during generate + image load; result fades in. Client-only.

## In progress / next
- [~] **Save / download result** — "Save to device" button under the render saves it to the gallery via `gal`. Bytes fetched through Firebase Storage (`fetchRenderBytes`). Added iOS `NSPhotoLibraryAddUsageDescription` + Android `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 29). Client-only — **needs a full rebuild (native permission change), not hot reload.**

## Not doing (for now)
- Tiny preview — kept as-is (per decision).
- "Drop your room image" copy — drag-drop wording on mobile, not critical.

## Known issues to address
- [~] **"Visualise again"** — `forceRetry` now bypasses the completed-cache (top return, status guard, claim txn, post-claim check); the button passes `forceRetry: true` when a result already exists. **Needs deploy + test.** Note: regenerating overwrites the result at the same storage path (no variation history kept).
- [~] **"Material required" hint** — `_generate()` now blocks with a snackbar when no material is selected.

## Notes
- **Tutorials unaffected** — the Visual Studio coachmark anchors (upload zone, description, materials row) are intact; no rebuild needed. A tip for the prompt-enhancer button can be added when built.
- **Local code not yet committed/pushed** (auto-upload + decouple + service change).
- **Deploy warnings (later, not urgent):** Node.js 20 runtime deprecated (decommission 2026-10-30); `firebase-functions` package outdated (upgrade has breaking changes).
