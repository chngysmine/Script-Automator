// Cloud Functions integration tests (run inside the emulator):
//   npm run test:functions
import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';
import { initializeApp as initAdmin } from 'firebase-admin/app';
import { getAuth as getAdminAuth } from 'firebase-admin/auth';
import { getFirestore as getAdminDb } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';

const projectId = 'demo-script-automator';
initAdmin({ projectId });
const adminDb = getAdminDb();
const adminAuth = getAdminAuth();

const clientApp = initializeApp({ projectId, apiKey: 'demo-key' }, 'client');
const clientAuth = getAuth(clientApp);
connectAuthEmulator(clientAuth, 'http://127.0.0.1:9099', { disableWarnings: true });
const functions = getFunctions(clientApp);
connectFunctionsEmulator(functions, '127.0.0.1', 5001);

async function waitFor(fn, { timeoutMs = 15000, intervalMs = 250 } = {}) {
  const start = Date.now();
  for (;;) {
    const value = await fn();
    if (value) return value;
    if (Date.now() - start > timeoutMs) throw new Error('Timed out waiting for condition');
    await new Promise((r) => setTimeout(r, intervalMs));
  }
}

async function createUser(email, claims) {
  const user = await adminAuth.createUser({ email, password: 'secret123', emailVerified: true });
  if (claims) await adminAuth.setCustomUserClaims(user.uid, claims);
  return user;
}

describe('banUser', () => {
  let adminUser;
  let target;

  before(async () => {
    adminUser = await createUser('admin@test.dev', { admin: true });
    target = await createUser('target@test.dev');
    await createUser('plain@test.dev');
  });

  after(async () => clientAuth.signOut());

  test('rejects non-admin callers', async () => {
    await signInWithEmailAndPassword(clientAuth, 'plain@test.dev', 'secret123');
    await assert.rejects(
      httpsCallable(functions, 'banUser')({ uid: target.uid, ban: true }),
      /permission-denied|not an admin/i,
    );
  });

  test('bans: disables Auth, mirrors Firestore and writes audit log', async () => {
    await signInWithEmailAndPassword(clientAuth, 'admin@test.dev', 'secret123');
    const res = await httpsCallable(functions, 'banUser')({ uid: target.uid, ban: true });
    assert.equal(res.data.success, true);

    const record = await adminAuth.getUser(target.uid);
    assert.equal(record.disabled, true);
    const userDoc = await adminDb.doc(`users/${target.uid}`).get();
    assert.equal(userDoc.get('is_banned'), true);
    const audit = await adminDb.collection('admin_audit_log')
      .where('target', '==', target.uid).where('action', '==', 'ban_user').get();
    assert.equal(audit.size, 1);
    assert.equal(audit.docs[0].get('actor_uid'), adminUser.uid);
  });

  test('unbans and re-enables Auth', async () => {
    await signInWithEmailAndPassword(clientAuth, 'admin@test.dev', 'secret123');
    await httpsCallable(functions, 'banUser')({ uid: target.uid, ban: false });
    const record = await adminAuth.getUser(target.uid);
    assert.equal(record.disabled, false);
    const userDoc = await adminDb.doc(`users/${target.uid}`).get();
    assert.equal(userDoc.get('is_banned'), false);
  });

  test('admins cannot ban themselves', async () => {
    await signInWithEmailAndPassword(clientAuth, 'admin@test.dev', 'secret123');
    await assert.rejects(
      httpsCallable(functions, 'banUser')({ uid: adminUser.uid, ban: true }),
      /failed-precondition|yourself/i,
    );
  });
});
