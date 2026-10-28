// Seeds the local Firebase emulators with demo data for the offline fallback.
// Run while emulators are up:  npm run demo:seed   (see npm run demo)
// Refuses to run unless every Admin SDK target points at an emulator.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { createHash } from 'node:crypto';

const required = ['FIREBASE_AUTH_EMULATOR_HOST', 'FIRESTORE_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST'];
const missing = required.filter((k) => !process.env[k]);
if (missing.length) {
  console.error(`Refusing to seed: ${missing.join(', ')} not set (would hit production).`);
  process.exit(1);
}

const projectId = process.env.GCLOUD_PROJECT || 'script-automator-bdbef';
const bucketName = `${projectId}.firebasestorage.app`;
initializeApp({ projectId, storageBucket: bucketName });
const auth = getAuth();
const db = getFirestore();
const bucket = getStorage().bucket();

export const DEMO_ACCOUNTS = {
  admin: { email: 'admin@demo.local', password: 'demo1234', displayName: 'Demo Admin' },
  user: { email: 'user@demo.local', password: 'demo1234', displayName: 'Demo User' },
};

async function upsertUser({ email, password, displayName }, claims) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch {
    user = await auth.createUser({ email, password, displayName, emailVerified: true });
  }
  if (claims) await auth.setCustomUserClaims(user.uid, claims);
  return user;
}

const SCRIPTS = [
  {
    id: 'demo_clock',
    name: 'Demo Clock',
    category: 'Utilities',
    description: 'Shows the current time and date.',
    code: `const now = new Date();
renderWidget({
  meta: { version: "1.0", target: "widget" },
  root: { type: "column", children: [
    { type: "text", content: now.toLocaleTimeString(), modifiers: { fontSize: 28, fontWeight: "bold" } },
    { type: "text", content: now.toDateString() }
  ] }
});`,
  },
  {
    id: 'demo_counter',
    name: 'Tap Counter',
    category: 'Productivity',
    description: 'Simple counter that logs to the console.',
    code: `let count = 0;
for (let i = 0; i < 3; i++) count++;
console.log("Count:", count);`,
  },
];

async function uploadScript(path, code) {
  const file = bucket.file(path);
  await file.save(code, { contentType: 'text/javascript' });
  // Emulator download URL (token-less, readable per storage.rules).
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
  return `http://${host}/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media`;
}

async function main() {
  const admin = await upsertUser(DEMO_ACCOUNTS.admin, { admin: true });
  const user = await upsertUser(DEMO_ACCOUNTS.user);

  await db.doc(`admins/${admin.uid}`).set({ email: DEMO_ACCOUNTS.admin.email, granted_by: 'seed', granted_at: FieldValue.serverTimestamp() });
  await db.doc(`users/${admin.uid}`).set({ displayName: 'Demo Admin', email: DEMO_ACCOUNTS.admin.email, role: 'admin' }, { merge: true });
  await db.doc(`users/${user.uid}`).set({ displayName: 'Demo User', email: DEMO_ACCOUNTS.user.email, role: 'user', is_banned: false }, { merge: true });

  await db.doc('app_config/global').set({
    maintenance_mode: false,
    gallery_submissions_enabled: true,
    ai_chat_model: 'gemini-3.8-flash',
    ai_completion_model: 'gemini-3.5-flash-lite',
    report_auto_block_threshold: 3,
  }, { merge: true });

  for (const s of SCRIPTS) {
    const fileUrl = await uploadScript(`gallery/${s.id}.js`, s.code);
    await db.doc(`gallery_published/${s.id}`).set({
      name: s.name, description: s.description, category: s.category, version: '1.0.0',
      author: 'Demo Admin', author_uid: admin.uid, icon: 'gear',
      file_url: fileUrl, file_size: Buffer.byteLength(s.code),
      sha256: createHash('sha256').update(s.code).digest('hex'),
      downloads: 0, code: s.code,
      published_at: FieldValue.serverTimestamp(), updated_at: FieldValue.serverTimestamp(),
    });
  }

  const pendingCode = 'console.log("Pending review from Demo User");';
  const pendingUrl = await uploadScript(`submissions/${user.uid}/demo_pending.js`, pendingCode);
  await db.doc('gallery_submissions/demo_pending').set({
    user_id: user.uid, script_id: 'demo_pending', name: 'Pending Demo Script',
    description: 'Submitted by the demo user, waiting for review.', category: 'Utilities',
    author: 'Demo User', version: '1.0.0', status: 'pending',
    file_url: pendingUrl, file_size: Buffer.byteLength(pendingCode),
    sha256: createHash('sha256').update(pendingCode).digest('hex'),
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('telemetry_logs').add({
    user_id: user.uid, script_id: 'demo_clock', event: 'run', status: 'success', duration_ms: 12,
    created_at: FieldValue.serverTimestamp(),
  });

  console.log('Seeded emulators for project', projectId);
  console.log(`  Admin web: ${DEMO_ACCOUNTS.admin.email} / ${DEMO_ACCOUNTS.admin.password}`);
  console.log(`  Mobile app: ${DEMO_ACCOUNTS.user.email} / ${DEMO_ACCOUNTS.user.password}`);
}

main().then(() => process.exit(0), (e) => {
  console.error(e);
  process.exit(1);
});
