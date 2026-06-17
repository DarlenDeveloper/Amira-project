// Firebase init for the Amira admin dashboard.
//
// Values default to the amira-interiors project config and can be overridden
// with Vite env vars (see .env.example) without touching code. If email/password
// sign-in ever fails with an api-key/domain error, register a Web app in the
// Firebase console (or run `flutterfire`/console) and drop the web config here.
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const env = import.meta.env;

const firebaseConfig = {
  apiKey: env.VITE_FB_API_KEY ?? 'AIzaSyAU6QIx6DRCTB4XMXunt4giuhDkRkfv82A',
  authDomain: env.VITE_FB_AUTH_DOMAIN ?? 'amira-interiors.firebaseapp.com',
  projectId: env.VITE_FB_PROJECT_ID ?? 'amira-interiors',
  storageBucket: env.VITE_FB_STORAGE_BUCKET ?? 'amira-interiors.firebasestorage.app',
  messagingSenderId: env.VITE_FB_MESSAGING_SENDER_ID ?? '1027356115889',
  appId: env.VITE_FB_APP_ID ?? '1:1027356115889:web:amira-admin',
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
