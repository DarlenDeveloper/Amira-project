# Amira Project

Monorepo for **Amira Interiors** — luxury interior design products for East Africa. Shared Firebase backend (`amira-interiors`) powers the mobile app, admin dashboard, and web shop.

## Packages

| Package | Stack | Description |
|---------|--------|-------------|
| [`amira_luxury`](./amira_luxury) | Flutter | Customer mobile app (iOS / Android) — catalog, Explore, orders, appointments, push notifications |
| [`amira_admin`](./amira_admin) | React + Vite | Admin dashboard for products, orders, and content |
| [`amira_explore_web`](./amira_explore_web) | React + Vite | Public Explore web shop |
| [`scripts`](./scripts) | Node | One-off utilities (category fixes, product uploads) |

## Quick start

### Mobile app (`amira_luxury`)

```bash
cd amira_luxury
flutter pub get
flutter run
```

Current release version: **1.0.8+8** (`version` in `pubspec.yaml`).

Build an App Store IPA:

```bash
cd amira_luxury
flutter build ipa --build-name=1.0.8 --build-number=8
```

IPA output: `amira_luxury/build/ios/ipa/`

### Admin dashboard (`amira_admin`)

```bash
cd amira_admin
npm install
npm run dev
```

### Explore web (`amira_explore_web`)

```bash
cd amira_explore_web
cp .env.example .env   # optional Firebase overrides
npm install
npm run dev
```

## Docs & legal

- [Project overview](./amira_project.md)
- [Privacy Policy](./PRIVACY_POLICY.md)
- [Terms of Service](./TERMS_OF_SERVICE.md)
- [License](./LICENSE)

## Tech notes

- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, FCM)
- **Mobile bundle ID:** `com.amiraluxury.mobile`
- **Web deploy:** Cloudflare Workers via Wrangler (`npm run deploy` in admin / explore)
