const admin = require('firebase-admin');

async function run() {
  try {
    const user = await admin.auth().getUserByEmail('chaunganpenny@gmail.com');
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    
    await admin.firestore().collection('users').doc(user.uid).set(
      { role: 'admin', updated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    
    await admin.firestore().collection('admins').doc(user.uid).set({
      email: user.email,
      granted_at: admin.firestore.FieldValue.serverTimestamp(),
      granted_by: 'system',
    });
    
    console.log(`Successfully granted admin to ${user.email} (${user.uid})`);
  } catch (err) {
    console.error('Failed:', err);
  }
}
run();
