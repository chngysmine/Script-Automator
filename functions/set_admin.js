const admin = require('firebase-admin');

// We need a service account key or GOOGLE_APPLICATION_CREDENTIALS.
// If not available, we can't run this. Let's check if firebase-admin can initialize default.
admin.initializeApp();

async function run() {
  try {
    const user = await admin.auth().getUserByEmail('chaunganpenny@gmail.com');
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log(`Successfully set admin claim for ${user.email} (${user.uid})`);
  } catch (e) {
    console.error(e);
  }
}
run();
