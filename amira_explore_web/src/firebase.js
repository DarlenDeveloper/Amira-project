// Firebase init for the Amira Explore web shop.
//
// This web app talks to the SAME Firebase project as the admin dashboard and
// the Flutter app ("amira-interiors"): it reads the live `products` catalogue
// and writes carts/orders against the shared data model. Config defaults to the
// amira-interiors web config and can be overridden with Vite env vars (see
// .env.example) without touching code.
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const env = import.meta.env;

const firebaseConfig = {
  apiKey: env.VITE_FB_API_KEY ?? 'AIzaSyAU6QIx6DRCTB4XMXunt4giuhDkRkfv82A',
  authDomain: env.VITE_FB_AUTH_DOMAIN ?? 'amira-interiors.firebaseapp.com',
  projectId: env.VITE_FB_PROJECT_ID ?? 'amira-interiors',
  storageBucket: env.VITE_FB_STORAGE_BUCKET ?? 'amira-interiors.firebasestorage.app',
  messagingSenderId: env.VITE_FB_MESSAGING_SENDER_ID ?? '1027356115889',
  appId: env.VITE_FB_APP_ID ?? '1:1027356115889:web:amira-explore',
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
