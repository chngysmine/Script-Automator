import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';

admin.initializeApp();

// ─── Security Constants ───
const ALLOWED_MODELS = ['gpt-3.5-turbo', 'gpt-4o', 'gpt-4o-mini'];
const MAX_TOKENS_CAP = 4096;
const MAX_MESSAGES = 20;
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 10;

/**
 * Secure OpenAI Proxy Function
 * 
 * Invoked securely by authenticated clients via Callable Function.
 * Protects the OpenAI API key and enforces rate limiting per user.
 */
export const openAiProxy = functions.https.onCall(async (request) => {
  // 1. Enforce Authentication
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // 2. Atomic Rate Limiting via Firestore Transaction
  const uid = request.auth.uid;
  const db = admin.firestore();
  const rateLimitRef = db.doc(`rate_limits/${uid}`);
  const now = Date.now();

  await db.runTransaction(async (txn) => {
    const doc = await txn.get(rateLimitRef);
    if (!doc.exists) {
      txn.set(rateLimitRef, { window_start: now, count: 1 });
      return;
    }
    const data = doc.data()!;
    const windowStart = data.window_start ?? 0;
    const count = data.count ?? 0;

    if (now - windowStart >= RATE_LIMIT_WINDOW_MS) {
      txn.set(rateLimitRef, { window_start: now, count: 1 });
    } else if (count >= RATE_LIMIT_MAX) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Max ${RATE_LIMIT_MAX} requests per minute.`
      );
    } else {
      txn.update(rateLimitRef, {
        count: admin.firestore.FieldValue.increment(1),
      });
    }
  });

  // 3. Validate Payload & Enforce Input Limits
  const { messages, prompt, model = 'gpt-4o', temperature = 0.2, max_tokens = 1000 } = request.data;

  if (!ALLOWED_MODELS.includes(model)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Model "${model}" is not allowed. Allowed: ${ALLOWED_MODELS.join(', ')}`
    );
  }

  const safeMaxTokens = Math.min(Math.max(1, Number(max_tokens) || 1000), MAX_TOKENS_CAP);
  const safeTemperature = Math.min(Math.max(0, Number(temperature) || 0.2), 2);
  
  let payloadMessages = messages;
  if (!payloadMessages) {
    if (!prompt || typeof prompt !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'The function must be called with valid "messages" array or a "prompt" string.'
      );
    }
    payloadMessages = [{ role: 'user', content: prompt }];
  }

  if (!Array.isArray(payloadMessages) || payloadMessages.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Messages must be a non-empty array.'
    );
  }

  if (payloadMessages.length > MAX_MESSAGES) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Too many messages. Maximum ${MAX_MESSAGES} allowed.`
    );
  }

  // 4. Fetch Secret Key
  const openAiKey = process.env.OPENAI_API_KEY;
  if (!openAiKey) {
    throw new functions.https.HttpsError(
      'internal',
      'OpenAI API key not configured on the server.'
    );
  }

  // 5. Forward to OpenAI with sanitized parameters
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openAiKey}`
      },
      body: JSON.stringify({
        model: model,
        messages: payloadMessages,
        max_tokens: safeMaxTokens,
        temperature: safeTemperature
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[OpenAI Error]', errorText);
      throw new functions.https.HttpsError('internal', 'OpenAI API request failed.');
    }

    const data = await response.json();
    return {
      success: true,
      result: data.choices[0].message.content
    };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error('[Proxy Error]', error);
    throw new functions.https.HttpsError('internal', 'Failed to communicate with OpenAI.');
  }
});

/**
 * Admin Role Management
 * 
 * Supports granting and revoking admin roles.
 * Grant: any existing admin can promote a user by email.
 * Revoke: only SUPER_ADMINS can demote an admin.
 */
export const setAdminRole = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const callerEmail = request.auth.token.email;
  const callerClaims = request.auth.token;
  const superAdmins = (process.env.SUPER_ADMINS || '').split(',').map(e => e.trim());

  const isCallerAdmin = callerClaims.admin === true || (callerEmail && superAdmins.includes(callerEmail));
  if (!isCallerAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'You are not an admin');
  }

  const { email, role = 'admin' } = request.data;
  if (!email || typeof email !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email is required');
  }

  // Revoke requires super admin
  if (role === 'user' && (!callerEmail || !superAdmins.includes(callerEmail))) {
    throw new functions.https.HttpsError('permission-denied', 'Only super admins can revoke admin roles');
  }

  // Find user by email
  let targetUser;
  try {
    targetUser = await admin.auth().getUserByEmail(email);
  } catch {
    throw new functions.https.HttpsError('not-found', `No user found with email: ${email}`);
  }

  const isGrant = role === 'admin';
  await admin.auth().setCustomUserClaims(targetUser.uid, { admin: isGrant });

  const db = admin.firestore();
  await db.collection('users').doc(targetUser.uid).set(
    { role: isGrant ? 'admin' : 'user', updated_at: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );

  if (isGrant) {
    await db.collection('admins').doc(targetUser.uid).set({
      email: email,
      granted_at: admin.firestore.FieldValue.serverTimestamp(),
      granted_by: callerEmail || 'unknown',
    });
  } else {
    await db.collection('admins').doc(targetUser.uid).delete();
  }

  return { success: true, message: `${isGrant ? 'Granted' : 'Revoked'} admin role for ${email}` };
});

/**
 * Storage Upload Validator
 * 
 * Triggers on file uploads to /submissions/ path.
 * Validates UTF-8, size limits, and flags suspicious patterns.
 */
export const validateSubmissionUpload = onObjectFinalized(async (event) => {
  const filePath = event.data.name;
  if (!filePath?.startsWith('submissions/')) return;

  const bucket = admin.storage().bucket(event.data.bucket);
  const file = bucket.file(filePath);

  try {
    const [content] = await file.download();
    const text = content.toString('utf-8');

    if (text.includes('\0')) {
      console.warn(`[Validate] Binary content detected in ${filePath} — deleting`);
      await file.delete();
      return;
    }

    if (content.length > 512 * 1024) {
      console.warn(`[Validate] File too large: ${filePath} (${content.length} bytes) — deleting`);
      await file.delete();
      return;
    }

    const dangerPatterns = [/eval\s*\(/i, /Function\s*\(/i, /__proto__/i, /constructor\s*\[/i];
    const violations = dangerPatterns.filter(p => p.test(text));
    if (violations.length > 0) {
      console.warn(`[Validate] Suspicious patterns in ${filePath}: ${violations.map(v => v.source).join(', ')}`);
      await file.setMetadata({
        metadata: { flagged: 'true', reason: 'suspicious_patterns', patterns: violations.map(v => v.source).join(',') }
      });
    }

    console.log(`[Validate] ${filePath} passed validation (${content.length} bytes)`);
  } catch (e) {
    console.error(`[Validate] Error processing ${filePath}:`, e);
  }
});

/**
 * Ban or unban a user and sync Firebase Auth.
 */
export const banUser = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const callerEmail = request.auth.token.email;
  const callerClaims = request.auth.token;
  const superAdmins = (process.env.SUPER_ADMINS || '').split(',').map(e => e.trim());
  const isCallerAdmin = callerClaims.admin === true || (callerEmail && superAdmins.includes(callerEmail));
  if (!isCallerAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'You are not an admin');
  }

  const { uid, ban } = request.data;
  if (!uid || typeof uid !== 'string' || typeof ban !== 'boolean') {
    throw new functions.https.HttpsError('invalid-argument', 'uid and ban are required');
  }

  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  const isBanned = ban === true;

  try {
    await admin.auth().updateUser(uid, { disabled: isBanned });
    await userRef.set({
      is_banned: isBanned,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await db.collection('admin_audit_log').add({
      action: isBanned ? 'ban_user' : 'unban_user',
      actor_email: request.auth.token.email || 'unknown',
      actor_uid: request.auth.uid,
      target: uid,
      details: isBanned ? 'User banned and disabled in Auth' : 'User unbanned and enabled in Auth',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: isBanned ? 'User banned successfully' : 'User unbanned successfully',
    };
  } catch (error) {
    console.error('[banUser] Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update user ban state');
  }
});

const readMetricsSnapshot = async () => {
  const db = admin.firestore();
  const [usersSnap, executionsSnap, widgetsSnap, recentLogsSnap] = await Promise.all([
    db.collection('users').count().get(),
    db.collection('telemetry_logs').where('event', '==', 'run').count().get(),
    db.collection('gallery_published').count().get(),
    db.collection('telemetry_logs').orderBy('created_at', 'desc').limit(200).get(),
  ]);

  const recentLogs = recentLogsSnap.docs.map(doc => doc.data());
  const crashCount = recentLogs.filter(log => log.event === 'crash').length;
  const crashRate = recentLogs.length > 0 ? crashCount / recentLogs.length : 0;

  return {
    total_users: usersSnap.data().count,
    total_executions: executionsSnap.data().count,
    total_widgets: widgetsSnap.data().count,
    crash_rate: crashRate,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };
};

export const aggregateMetrics = onSchedule({ schedule: 'every 5 minutes' }, async () => {
  try {
    const metrics = await readMetricsSnapshot();
    await admin.firestore().doc('app_config/metrics').set(metrics, { merge: true });
    console.log('[aggregateMetrics] metrics updated');
  } catch (error) {
    console.error('[aggregateMetrics] Error:', error);
  }
});

import { onDocumentCreated } from 'firebase-functions/v2/firestore';

export const autoGrantAdminTrigger = onDocumentCreated('admin_requests/{docId}', async (event) => {
  const email = event.data?.data()?.email;
  if (!email) return;

  const targetUser = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(targetUser.uid, { admin: true });

  const db = admin.firestore();
  await db.collection('users').doc(targetUser.uid).set(
    { role: 'admin', updated_at: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );

  await db.collection('admins').doc(targetUser.uid).set({
    email: email,
    granted_at: admin.firestore.FieldValue.serverTimestamp(),
    granted_by: 'system_trigger',
  });

  console.log(`Auto-granted admin role to ${email}`);
});
