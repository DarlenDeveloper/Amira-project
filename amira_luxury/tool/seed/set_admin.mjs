// Grants the `admin: true` custom claim to an admin dashboard account
// (and creates the account if it doesn't exist yet).
//
// Run:
//   cd amira_luxury/tool/seed && npm install
//   GOOGLE_APPLICATION_CREDENTIALS=/abs/path/key.json \
//     node set_admin.mjs admin@amira.com "a-strong-password"
//
// The password arg is only used when the account doesn't exist. After running,
// the user must sign out / get a fresh token for the claim to take effect.

import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'node:fs';

const [, , email, password] = process.argv;
if (!email) {
  console.error('Usage: node set_admin.mjs <email> [password]');
  process.exit(1);
}

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
initializeApp({
  credential: keyPath
    ? cert(JSON.parse(readFileSync(keyPath, 'utf8')))
    : applicationDefault(),
});

const auth = getAuth();

async function run() {
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      if (!password) {
        console.error(`No account for ${email}. Pass a password to create one.`);
        process.exit(1);
      }
      user = await auth.createUser({ email, password, emailVerified: true });
      console.log(`Created account ${email}.`);
    } else {
      throw e;
    }
  }
  await auth.setCustomUserClaims(user.uid, { admin: true });
  console.log(`Granted admin claim to ${email} (${user.uid}).`);
  console.log('Sign out and back in on the dashboard to refresh the token.');
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
