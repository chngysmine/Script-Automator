// Firestore + Storage security rules tests (run inside the emulator):
//   npm run test:rules
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, addDoc, collection, serverTimestamp, deleteDoc, writeBatch,
} from 'firebase/firestore';
import { ref, uploadString, getBytes } from 'firebase/storage';

const root = new URL('../../', import.meta.url);
let env;

const USER = { sub: 'alice', email: 'alice@example.com', email_verified: true, firebase: { sign_in_provider: 'password' } };
const OTHER = { sub: 'bob', email: 'bob@example.com', email_verified: true, firebase: { sign_in_provider: 'password' } };
const GUEST = { sub: 'guest', firebase: { sign_in_provider: 'anonymous' } };
const BANNED = { sub: 'mallory', email: 'm@example.com', firebase: { sign_in_provider: 'password' } };
const ADMIN = { sub: 'root', email: 'root@example.com', admin: true, firebase: { sign_in_provider: 'password' } };

const as = (claims) => env.authenticatedContext(claims.sub, claims).firestore();
const storageAs = (claims) => env.authenticatedContext(claims.sub, claims).storage();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-script-automator',
    firestore: { rules: readFileSync(new URL('firestore.rules', root), 'utf8') },
    storage: { rules: readFileSync(new URL('storage.rules', root), 'utf8') },
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), { displayName: 'Alice' });
    await setDoc(doc(db, 'users/mallory'), { is_banned: true });
    await setDoc(doc(db, 'gallery_submissions/sub1'), { user_id: 'alice', name: 'x', status: 'pending' });
  });
});

describe('users', () => {
  test('owner can update profile fields', async () => {
    await assertSucceeds(updateDoc(doc(as(USER), 'users/alice'), { bio: 'hi' }));
  });
  test('owner cannot grant themselves a role', async () => {
    await assertFails(updateDoc(doc(as(USER), 'users/alice'), { role: 'admin' }));
  });
  test('owner cannot touch ban fields', async () => {
    await assertFails(updateDoc(doc(as(USER), 'users/alice'), { is_banned: false }));
  });
  test('new profile cannot carry a role', async () => {
    await assertFails(setDoc(doc(as(OTHER), 'users/bob'), { role: 'admin' }));
  });
  test('users cannot read others; admins can', async () => {
    await assertFails(getDoc(doc(as(OTHER), 'users/alice')));
    await assertSucceeds(getDoc(doc(as(ADMIN), 'users/alice')));
  });
  test('banned user cannot write own scripts', async () => {
    await assertFails(setDoc(doc(as(BANNED), 'users/mallory/scripts/s1'), { name: 'x' }));
    await assertSucceeds(setDoc(doc(as(USER), 'users/alice/scripts/s1'), { name: 'x' }));
  });
});

describe('script_reports + script_moderation (batched report)', () => {
  const SCRIPT = 'weather';

  /** Mirrors CloudGalleryRepository.reportScript: report + counter in one batch. */
  function reportBatch(claims, { scriptId = SCRIPT, reportId, count, blocked, extra = {} }) {
    const db = as(claims);
    const batch = writeBatch(db);
    batch.set(doc(db, 'script_reports', reportId ?? `${scriptId}_${claims.sub}`), {
      script_id: scriptId, reporter_uid: claims.sub, reason: 'spam', created_at: serverTimestamp(),
    });
    batch.set(doc(db, 'script_moderation', scriptId), {
      reports_count: count,
      is_blocked: blocked,
      updated_at: serverTimestamp(),
      ...extra,
    }, { merge: true });
    return batch.commit();
  }

  async function seedModeration(data) {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'script_moderation', SCRIPT), data);
    });
  }

  test('first report creates the counter', async () => {
    await assertSucceeds(reportBatch(USER, { count: 1, blocked: false }));
  });

  test('second report by the same user is rejected', async () => {
    await assertSucceeds(reportBatch(USER, { count: 1, blocked: false }));
    await assertFails(reportBatch(USER, { count: 2, blocked: false }));
  });

  test('counter must move by exactly +1', async () => {
    await seedModeration({ reports_count: 2, is_blocked: false });
    await assertFails(reportBatch(USER, { count: 5, blocked: false }));
    await assertSucceeds(reportBatch(USER, { count: 3, blocked: false }));
  });

  test('auto-blocks exactly at the configured threshold', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'app_config/global'), { report_auto_block_threshold: 3 });
    });
    await seedModeration({ reports_count: 1, is_blocked: false });
    // Below threshold: blocking early is rejected.
    await assertFails(reportBatch(USER, { count: 2, blocked: true }));
    await assertSucceeds(reportBatch(USER, { count: 2, blocked: false }));
    // At threshold: must block.
    await assertFails(reportBatch(OTHER, { count: 3, blocked: false }));
    await assertSucceeds(reportBatch(OTHER, { count: 3, blocked: true, extra: { blocked_reason: 'auto_reports_threshold' } }));
  });

  test('users can never unblock or bypass an admin override', async () => {
    await seedModeration({ reports_count: 9, is_blocked: true });
    await assertFails(reportBatch(USER, { count: 10, blocked: false }));
    await seedModeration({ reports_count: 9, is_blocked: false, admin_override: true });
    await assertFails(reportBatch(USER, { count: 10, blocked: true }));
    await assertFails(reportBatch(USER, { count: 10, blocked: false, extra: { admin_override: false } }));
    await assertSucceeds(reportBatch(USER, { count: 10, blocked: false }));
  });

  test('counter cannot change without a report, and reports need the counter', async () => {
    await assertFails(setDoc(doc(as(USER), 'script_moderation', SCRIPT), {
      reports_count: 1, is_blocked: false, updated_at: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(as(USER), `script_reports/${SCRIPT}_alice`), {
      script_id: SCRIPT, reporter_uid: 'alice', created_at: serverTimestamp(),
    }));
  });

  test('wrong id, impersonation, guest and banned users are rejected', async () => {
    await assertFails(reportBatch(USER, { reportId: 'random', count: 1, blocked: false }));
    await assertFails(reportBatch(USER, { reportId: `${SCRIPT}_bob`, count: 1, blocked: false }));
    await assertFails(reportBatch(GUEST, { count: 1, blocked: false }));
    await assertFails(reportBatch(BANNED, { count: 1, blocked: false }));
  });

  test('admins still write moderation directly', async () => {
    await assertSucceeds(setDoc(doc(as(ADMIN), 'script_moderation', SCRIPT), { is_blocked: true, admin_override: false }));
    await assertSucceeds(getDoc(doc(as(USER), 'script_moderation', SCRIPT)));
  });
});

describe('gallery_submissions', () => {
  const sub = (uid, extra = {}) => ({ user_id: uid, name: 'Timer', description: 'd', status: 'pending', ...extra });
  test('registered user can submit pending', async () => {
    await assertSucceeds(addDoc(collection(as(USER), 'gallery_submissions'), sub('alice')));
  });
  test('guest, impersonation, self-approval and review fields are rejected', async () => {
    await assertFails(addDoc(collection(as(GUEST), 'gallery_submissions'), sub('guest')));
    await assertFails(addDoc(collection(as(USER), 'gallery_submissions'), sub('bob')));
    await assertFails(addDoc(collection(as(USER), 'gallery_submissions'), sub('alice', { status: 'approved' })));
    await assertFails(addDoc(collection(as(USER), 'gallery_submissions'), sub('alice', { reviewed_by: 'alice' })));
  });
  test('only admins can review', async () => {
    await assertFails(updateDoc(doc(as(USER), 'gallery_submissions/sub1'), { status: 'approved' }));
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'gallery_submissions/sub1'), {
      status: 'rejected', reject_reason: 'Broken', reviewed_by: 'root', reviewed_at: serverTimestamp(),
    }));
  });
  test('author can read own submission, others cannot', async () => {
    await assertSucceeds(getDoc(doc(as(USER), 'gallery_submissions/sub1')));
    await assertFails(getDoc(doc(as(OTHER), 'gallery_submissions/sub1')));
  });
});

describe('telemetry, feedback, config', () => {
  test('telemetry create is validated and immutable', async () => {
    const db = as(USER);
    await assertSucceeds(addDoc(collection(db, 'telemetry_logs'), {
      user_id: 'alice', script_id: 's1', event: 'run', status: 'success', duration_ms: 3, created_at: serverTimestamp(),
    }));
    await assertFails(addDoc(collection(db, 'telemetry_logs'), {
      user_id: 'alice', script_id: 's1', event: 'hack', status: 'x',
    }));
    await assertFails(addDoc(collection(db, 'telemetry_logs'), {
      user_id: 'bob', script_id: 's1', event: 'run', status: 'x',
    }));
  });
  test('feedback requires own uid and bounded fields', async () => {
    const ok = { user_id: 'alice', title: 'Bug', description: 'Steps', category: 'bug', status: 'pending' };
    await assertSucceeds(addDoc(collection(as(USER), 'user_feedback'), ok));
    await assertFails(addDoc(collection(as(USER), 'user_feedback'), { ...ok, title: 'x'.repeat(201) }));
  });
  test('app_config readable by users, writable by admins only', async () => {
    await assertSucceeds(getDoc(doc(as(USER), 'app_config/global')));
    await assertFails(setDoc(doc(as(USER), 'app_config/global'), { ai_chat_model: 'x' }));
    await assertSucceeds(setDoc(doc(as(ADMIN), 'app_config/global'), { ai_chat_model: 'gemini-3.8-flash' }));
  });
  test('unknown collections are denied', async () => {
    await assertFails(getDoc(doc(as(ADMIN), 'github_activity/a')));
    await assertFails(setDoc(doc(as(USER), 'random/a'), { a: 1 }));
  });
  test('admin audit log is append-only', async () => {
    const db = as(ADMIN);
    const created = await assertSucceeds(addDoc(collection(db, 'admin_audit_log'), { action: 'x' }));
    await assertFails(deleteDoc(created));
  });
});

describe('storage', () => {
  test('submission readable only by owner or admin', async () => {
    const path = 'submissions/alice/s1.js';
    await assertSucceeds(uploadString(ref(storageAs(USER), path), 'x()', 'raw', { contentType: 'text/javascript' }));
    await assertSucceeds(getBytes(ref(storageAs(USER), path)));
    await assertSucceeds(getBytes(ref(storageAs(ADMIN), path)));
    await assertFails(getBytes(ref(storageAs(OTHER), path)));
  });
  test('guests cannot upload submissions; non-admins cannot publish', async () => {
    await assertFails(uploadString(ref(storageAs(GUEST), 'submissions/guest/a.js'), 'x', 'raw', { contentType: 'text/javascript' }));
    await assertFails(uploadString(ref(storageAs(USER), 'gallery/a.js'), 'x', 'raw', { contentType: 'text/javascript' }));
    await assertSucceeds(uploadString(ref(storageAs(ADMIN), 'gallery/a.js'), 'x', 'raw', { contentType: 'text/javascript' }));
  });
});
