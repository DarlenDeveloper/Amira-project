# Amira — Backend Data Model (Firestore contract)

The Flutter app (`amira_luxury`) and the admin web (`amira_admin`) are two
clients over **one Firestore database**. This file is the shared contract: the
seven collections, their fields, who writes them, and who reads them. Both teams
build against this — change it here first, then in code.

Backend is **Firebase** (Auth + Firestore). No separate API server.

## Ownership at a glance

| Collection      | Written by        | Read by            | Direction        |
|-----------------|-------------------|--------------------|------------------|
| `products`      | Admin             | App + Admin        | admin → app      |
| `portfolio`     | Admin             | App + Admin        | admin → app      |
| `notifications` | Admin             | App + Admin        | admin → app      |
| `orders`        | App (user)        | App + Admin        | user ↔ admin     |
| `appointments`  | App (user)        | App + Admin        | user ↔ admin     |
| `conversations` | App (user) + AI   | App + Admin        | user ↔ admin     |
| `users`         | App (user)        | App + Admin        | user → admin     |

- **Admin-authored, app reads:** products, portfolio, notifications.
- **User-authored, admin manages status:** orders, appointments, conversations.
- **User-authored, admin aggregates:** users (→ admin "customers" view).

## Image strategy

Product/portfolio images come **only from the backend** via an `imageUrl`
(admin-uploaded, e.g. Firebase Storage). There is **no bundled-asset fallback** —
the seeded bundled images were dummy data and the client will replace them.

When a doc has no `imageUrl` (or it fails to load), the app shows a neutral
**"no image" placeholder** (see `lib/widgets/product_image.dart`) — never a
bundled asset. `imageKey` may still exist on a doc as a stable slug/id, but it
is not used for image display.

## Collections

### `products/{productId}`  — admin-authored
Union of the app's Explore/Home data and the admin catalog fields.
```
name        string   // join key today; "PVC Marble Sheets"
imageKey    string   // "pvc-marble-sheet" — resolves to bundled asset
category    string   // "Wall Panels" | "Marble Sheets" | "Stone" | "Lighting" |
                     // "Flooring" | "Blinds" | "Steel" | "Boards"
value       number   // unit price, e.g. 56
unit        string   // "sqm" | "unit" | "m" | "sheet"
about       string   // long description (app item details)
desc        string   // short tagline (app home card)
badge       string?  // "LUXURY" | "BESTSELLER" | "NEW" | null
stock       number   // inventory count
status      string   // "active" | "low" | "out"  (drives app availability)
order       number?  // display order
createdAt   ts
updatedAt   ts
```

### `portfolio/{portfolioId}`  — admin-authored
```
title       string   // "Living Room Design" (app shows as the project label)
imageUrl    string?  // admin-uploaded; "no image" placeholder when absent
room        string    // "Living Room" | "Bedroom" | "Kitchen" | "Office" ...
location    string    // "Kampala, UG"
size        string    // "60 m²"
productId   string    // the Amira product used on the project (ref to products)
productName string    // denormalised product name — shown where price used to be
status      string    // "published" | "draft" | "concept"
order       number?
createdAt   ts
updatedAt   ts
```
App reads **only `status == "published"`**. Per spec, the app shows the
**product used**, not a price.

### `notifications/{notificationId}`  — admin-authored (broadcast)
```
type        string   // "collection" | "offer" | "order" | "design"
title       string
body        string
audience    string   // "all" | "order:AM-10246" | "user:{uid}"
sentAt      ts
delivered   number?  // admin metric
```
App maps `type` → icon/color client-side. **Read state is per-user**, NOT on
this doc — see per-user tracking below.

#### Per-user read state
`users/{uid}/notificationState/{notificationId}` → `{ readAt: ts }`.
App computes "unread" = broadcast docs matching the user's audience that have no
state doc (or no `readAt`). Keeps the broadcast doc clean.

### `orders/{orderId}`  — user-authored, admin advances status
```
orderId     string   // "AM-10248" (human ref; doc id can match)
uid         string   // owner — app queries by this
customer    string   // denormalised from profile
email       string
items       [ { productId, name, imageKey, unit, value, qty } ]
itemCount   number   // == items.length-ish (admin "items")
total       number   // subtotal + delivery
status      string   // pending | processing | paid | shipped | delivered | cancelled
createdAt   ts
updatedAt   ts
```
App creates as `pending`. Admin advances status. App reads its own back
(Profile → Orders).

### `appointments/{appointmentId}`  — user-authored, admin advances status
```
appointmentId string  // "AP-2042"
uid           string
customer      string
email         string
type          string   // "Design Consultation" | "Site Visit" | "Showroom Visit"
date          string    // or ts
time          string
note          string
status        string    // requested | confirmed | completed | cancelled
createdAt     ts
updatedAt     ts
```
App creates as `requested`.

### `conversations/{conversationId}`  — user + AI authored, admin reviews
```
uid         string
customer    string
email       string
status      string   // "open" | "resolved"
updatedAt   ts
createdAt   ts
// subcollection:
messages/{messageId} → { from: "user"|"agent", text, time: ts }
```
App `isUser:true` → `from:"user"`; AI reply → `from:"agent"`. Gemini
integration is a later step; thread storage comes first.

### `users/{uid}`  — user-authored (already live)
```
name, email, phone, address, photoUrl, createdAt, updatedAt
```
Admin "customers" = this doc + aggregates (`orders` count, `spent`) derived from
the `orders` collection. No separate customers collection.

## Security rules — intent
- `products`, `portfolio`: public read for signed-in users; **write = admin only**.
- `notifications`: signed-in read; write = admin only. `notificationState`
  read/write = owner only.
- `orders`, `appointments`, `conversations`: a user reads/writes **only docs
  where `uid == request.auth.uid`**; status transitions = admin only. Admin
  reads all.
- Admin = custom claim `admin: true` (set via Admin SDK / console), checked in
  rules as `request.auth.token.admin == true`.
- `users`: owner-only (already enforced).
