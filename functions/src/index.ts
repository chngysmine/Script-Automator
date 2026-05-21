import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();

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

  // 2. Rate Limiting: max 10 requests per minute per user
  const uid = request.auth.uid;
  const rateLimitRef = admin.firestore().doc(`rate_limits/${uid}`);
  const now = Date.now();
  const windowMs = 60_000;
  const maxRequests = 10;

  const rateLimitDoc = await rateLimitRef.get();
  const rlData = rateLimitDoc.data();
  if (rlData) {
    const windowStart = rlData.window_start ?? 0;
    const count = rlData.count ?? 0;
    if (now - windowStart < windowMs && count >= maxRequests) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Max ${maxRequests} requests per minute.`
      );
    }
    if (now - windowStart >= windowMs) {
      await rateLimitRef.set({ window_start: now, count: 1 });
    } else {
      await rateLimitRef.update({
        count: admin.firestore.FieldValue.increment(1),
      });
    }
  } else {
    await rateLimitRef.set({ window_start: now, count: 1 });
  }

  // 3. Validate Payload
  const { messages, prompt, model = 'gpt-4o', temperature = 0.2, max_tokens = 1000 } = request.data;
  
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

  // 4. Fetch Secret Key (In production, this should use Secret Manager)
  const openAiKey = process.env.OPENAI_API_KEY;
  if (!openAiKey) {
    throw new functions.https.HttpsError(
      'internal',
      'OpenAI API key not configured on the server.'
    );
  }

  // 4. Forward to OpenAI
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
        max_tokens: max_tokens,
        temperature: temperature
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
    console.error('[Proxy Error]', error);
    throw new functions.https.HttpsError('internal', 'Failed to communicate with OpenAI.');
  }
});

/**
 * Admin Role Setter
 * 
 * Only executed once per user via a highly-secured endpoint or 
 * manually triggered by an existing admin. For safety, this currently 
 * relies on an environment-defined super-admin email list.
 */
export const setAdminRole = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const email = request.auth.token.email;
  const superAdmins = (process.env.SUPER_ADMINS || '').split(',');

  if (email && superAdmins.includes(email)) {
    const uid = request.auth.uid;
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    
    // Also update firestore users collection
    await admin.firestore().collection('users').doc(uid).set(
      { role: 'admin', updated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    
    return { success: true, message: `Granted admin role to ${email}` };
  } else {
    throw new functions.https.HttpsError('permission-denied', 'You are not a super admin');
  }
});
