# Amira — Backend Implementation Plan (page by page)

Living checklist for wiring Firestore behind the app + admin. We go **page by
page**. Tick items as we land them. See `data-model.md` for the schema contract.

**Done so far:** Auth only (email / Google / phone-password, `users/{uid}`
profiles, rules for users). Everything else below is dummy data.

**Ground rules**
- Home featured **card swiper (the section above "Our Portfolio") stays static**
  (bundled assets, not wired). Everything else on Home is wired.
- Images stay bundled; admin-authored docs carry an `imageKey` both clients resolve.
- Admin-authored: products, portfolio, notifications. User-authored: orders,
  appointments, conversations.
- Don't break the luxury UI — wiring only, visuals unchanged unless asked.

---

## Phase 0 — Foundation (shared, do first)
- [ ] Finalise `data-model.md` collections (done — revisit if reality differs).
- [ ] Write `firestore.rules` for all 7 collections + admin custom-claim check.
      *(products rules added; deferred polishing the rest per request.)*
- [x] Product images come from `imageUrl` only (no bundled-asset fallback);
      `lib/widgets/product_image.dart` shows a "no image" placeholder otherwise.
- [ ] Stand up Firebase in `amira_admin` (SDK config, env, app init).
- [ ] Real admin auth in `amira_admin` (replace placeholder; admin allowlist / claim).
- [x] Seed `products` (11 items) via `tool/seed/seed_products.mjs` (run once).

---

## App pages (`amira_luxury`)

### Home  (`home_screen.dart`)
- [x] Featured card **swiper section above "Our Portfolio"** (`_featuredCards`)
      — **left static**, bundled assets, no wiring. Only part of Home unchanged.
- [x] "Our Portfolio" strip (`_recommendations`) → reads `portfolio` where
      `status == published`. Shows the **product used** (not a price), per spec.
      Remote images via `imageUrl` (no-image placeholder); shimmer while loading.
- [ ] Notification bell badge → live unread count (per-user state).
- [ ] Search bar "Ask Amira agent" → routes into AI Agent (later phase).

### Explore  (`explore_screen.dart`)
- [x] Product grid → stream `products` (replace `_materials` dummy list).
- [ ] Reflect `status` (`out`/`low`) on cards. *(deferred — no UI change rule;
      `status` is on the model, just not surfaced visually yet.)*
- [ ] Filter pills → real `category` values. *(deferred — original
      ALL/FLUTED/WPC pills kept verbatim per no-UI-change; they don't filter,
      matching original behaviour.)*
- [x] Favourite heart → persist per-user (`users/{uid}/favourites`).

### Item details  (`item_details_screen.dart`)
- [x] Load product from `products` doc (passed in as `Product`).
- [x] "Order" → create `orders` doc (status `pending`).
- [x] "Book Appointment" → create `appointments` doc (status `requested`).
- [x] Favourite toggle persists (via Explore card; no item-details UI added).
- [x] Cart "add" button (top bag icon) → write to cart.

### Cart  (`cart_screen.dart`)
- [x] Replace local `CartItem` list with per-user cart (`users/{uid}/cart`).
- [x] Add-to-cart from item details feeds this.
- [x] "Checkout" → create `orders` doc from cart, then clear cart.

### Notifications  (`notifications_screen.dart`)
- [ ] Read `notifications` filtered by audience (all / user / order).
- [ ] Map `type` → icon/color (client-side).
- [ ] Mark-as-read / delete → per-user `notificationState`.

### Profile  (`profile_screen.dart`)
- [x] Orders menu → list user's `orders` (by `uid`), show status (`OrdersScreen`).
- [x] Appointments menu → list user's `appointments` (`AppointmentsScreen`).
- [x] (Profile + edit already wired to `users/{uid}`.)

### AI Agent  (`ai_agent_screen.dart`)
- [ ] Persist threads → `conversations` + `messages` subcollection.
- [ ] Wire real Gemini responses (replace simulated reply). **Later phase.**

---

## Admin pages (`amira_admin`)

Firebase wired: `src/firebase.js` (init), `src/db.js` (`useCollection` hook +
CRUD/storage/format helpers), `src/components/Thumb.jsx` (image / no-image).
Admin gated by `admin: true` claim (set via `tool/seed/set_admin.mjs`).

### Auth / shell
- [x] Real Firebase admin auth + claim gate (`auth.jsx`, `Login.jsx`, `App.jsx`).

### Products  (`pages/Products.jsx`)
- [x] Read live `products` (categories/counts derived from data).
- [ ] CRUD against `products` (create/edit/stock/status/category, image upload).

### Portfolio  (`pages/Portfolio.jsx`)
- [x] Read live `portfolio`; shows product used (not price).
- [ ] CRUD against `portfolio` (publish/draft/concept, product picker, image upload).

### Orders  (`pages/Orders.jsx`)
- [x] Read all `orders` (live, newest first, status counts/total).
- [ ] Advance status through lifecycle (write).

### Appointments  (`pages/Appointments.jsx`)
- [x] Read all `appointments` (live).
- [ ] Confirm / complete / cancel + schedule date/time (write).

### Conversations  (`pages/Conversations.jsx`)
- [x] Read `conversations` threads + messages subcollection (empty until app writes).
- [ ] Admin reply (write) — with Gemini phase.

### Customers  (`pages/Customers.jsx`)
- [x] Read `users` + aggregate `orders` count / spend.

### Notifications  (`pages/Notifications.jsx`)
- [x] Read live `notifications`.
- [ ] Compose/send → write `notifications` (type, audience, body).

### Overview  (`pages/Overview.jsx`)
- [x] Dashboard metrics from real collections.

---

## Suggested build order
1. Phase 0 foundation (rules, seed, admin Firebase + auth).
2. Products end-to-end (Explore + Item details ← admin Products CRUD). Highest value.
3. Portfolio (Home strip ← admin Portfolio CRUD).
4. Orders + Cart (app create → admin manage → Profile read-back).
5. Appointments (app create → admin manage → Profile read-back).
6. Notifications (admin send → app feed + per-user read state).
7. Conversations storage, then Gemini.
8. Admin Customers + Overview aggregates.
