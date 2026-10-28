import { initializeApp } from 'firebase-admin/app';
import { getAuth, UserRecord } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';

import { requireAdmin, isSuperAdmin } from './auth';

initializeApp();
setGlobalOptions({ maxInstances: 10 });

/**
 * Grants (`role: 'admin'`) or revokes (`role: 'user'`) the admin custom claim.
 * Any admin can grant; only bootstrap super admins can revoke.
 */
export const setAdminRole = onCall(async (request) => {
  const caller = requireAdmin(request);
  const { email, role = 'admin' } = request.data ?? {};
  if (!email || typeof email !== 'string') {
    throw new HttpsError('invalid-argument', 'Valid email is required');
  }
  if (role !== 'admin' && role !== 'user') {
    throw new HttpsError('invalid-argument', "role must be 'admin' or 'user'");
  }
  if (role === 'user' && !isSuperAdmin(caller.email)) {
    throw new HttpsError('permission-denied', 'Only super admins can revoke admin roles');
  }

  let target: UserRecord;
  try {
    target = await getAuth().getUserByEmail(email);
  } catch {
    throw new HttpsError('not-found', `No user found with email: ${email}`);
  }

  const isGrant = role === 'admin';
  const existingClaims = target.customClaims ?? {};
  await getAuth().setCustomUserClaims(target.uid, { ...existingClaims, admin: isGrant });

  const db = getFirestore();
  const batch = db.batch();
  batch.set(
    db.collection('users').doc(target.uid),
    { role: isGrant ? 'admin' : 'user', updated_at: FieldValue.serverTimestamp() },
    { merge: true },
  );
  const adminRef = db.collection('admins').doc(target.uid);
  if (isGrant) {
    batch.set(adminRef, {
      email,
      granted_at: FieldValue.serverTimestamp(),
      granted_by: caller.email || caller.uid,
    });
  } else {
    batch.delete(adminRef);
  }
  batch.set(db.collection('admin_audit_log').doc(), {
    action: isGrant ? 'grant_admin' : 'revoke_admin',
    actor_email: caller.email || 'unknown',
    actor_uid: caller.uid,
    target: email,
    details: `${isGrant ? 'Granted' : 'Revoked'} admin role`,
    timestamp: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  return { success: true, message: `${isGrant ? 'Granted' : 'Revoked'} admin role for ${email}` };
});

/**
 * Bans/unbans a user: disables Firebase Auth, revokes refresh tokens on ban,
 * mirrors `is_banned` in Firestore and writes an audit entry.
 */
export const banUser = onCall(async (request) => {
  const caller = requireAdmin(request);
  const { uid, ban } = request.data ?? {};
  if (!uid || typeof uid !== 'string' || typeof ban !== 'boolean') {
    throw new HttpsError('invalid-argument', 'uid and ban are required');
  }
  if (uid === caller.uid) {
    throw new HttpsError('failed-precondition', 'You cannot ban yourself');
  }

  const db = getFirestore();
  try {
    await getAuth().updateUser(uid, { disabled: ban });
    if (ban) await getAuth().revokeRefreshTokens(uid);

    const batch = db.batch();
    batch.set(
      db.collection('users').doc(uid),
      {
        is_banned: ban,
        banned_at: ban ? FieldValue.serverTimestamp() : FieldValue.delete(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    batch.set(db.collection('admin_audit_log').doc(), {
      action: ban ? 'ban_user' : 'unban_user',
      actor_email: caller.email || 'unknown',
      actor_uid: caller.uid,
      target: uid,
      details: ban ? 'User banned, Auth disabled, sessions revoked' : 'User unbanned, Auth enabled',
      timestamp: FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return { success: true, banned: ban, message: ban ? 'User banned' : 'User unbanned' };
  } catch (error) {
    console.error('[banUser] Error:', error);
    throw new HttpsError('internal', 'Failed to update user ban state');
  }
});

// Reports are aggregated by firestore.rules (batched report + counter), so no
// Firestore trigger is needed. The two event functions below need extra IAM
// bindings (project Owner) to deploy; production deploys list callables
// explicitly — see PROJECT_CONTEXT.md §4. They always run in the emulators.

/**
 * Validates uploads under submissions/: deletes binary or oversized files and
 * flags suspicious patterns in metadata (surfaced to reviewers in the admin).
 */
// Storage triggers must run in the bucket's region (us-east1).
export const validateSubmissionUpload = onObjectFinalized({ region: 'us-east1' }, async (event) => {
  const filePath = event.data.name;
  if (!filePath?.startsWith('submissions/')) return;

  const file = getStorage().bucket(event.data.bucket).file(filePath);
  try {
    if (Number(event.data.size) > 512 * 1024) {
      console.warn(`[Validate] File too large: ${filePath} — deleting`);
      await file.delete();
      return;
    }
    const [content] = await file.download();
    const text = content.toString('utf-8');
    if (text.includes('\0')) {
      console.warn(`[Validate] Binary content in ${filePath} — deleting`);
      await file.delete();
      return;
    }
    const dangerPatterns = [/eval\s*\(/i, /Function\s*\(/i, /__proto__/i, /constructor\s*\[/i];
    const violations = dangerPatterns.filter((p) => p.test(text));
    if (violations.length > 0) {
      await file.setMetadata({
        metadata: {
          flagged: 'true',
          reason: 'suspicious_patterns',
          patterns: violations.map((v) => v.source).join(','),
        },
      });
    }
  } catch (e) {
    console.error(`[Validate] Error processing ${filePath}:`, e);
  }
});

/** Pre-aggregates dashboard KPIs into app_config/metrics every 5 minutes. */
export const aggregateMetrics = onSchedule({ schedule: 'every 5 minutes' }, async () => {
  const db = getFirestore();
  try {
    const [users, runs, published, widgets, recentLogs] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('telemetry_logs').where('event', '==', 'run').count().get(),
      db.collection('gallery_published').count().get(),
      db.collection('widget_stats').count().get(),
      db.collection('telemetry_logs').orderBy('created_at', 'desc').limit(200).get(),
    ]);
    const logs = recentLogs.docs.map((d) => d.data() as { event?: string });
    const crashes = logs.filter((l) => l.event === 'crash').length;

    await db.doc('app_config/metrics').set(
      {
        total_users: users.data().count,
        total_executions: runs.data().count,
        total_published: published.data().count,
        total_widget_deploys: widgets.data().count,
        crash_rate: logs.length > 0 ? crashes / logs.length : 0,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } catch (error) {
    console.error('[aggregateMetrics] Error:', error);
  }
});
