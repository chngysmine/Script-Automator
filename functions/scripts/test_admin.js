const admin = require('firebase-admin');

// Using Application Default Credentials from firebase login
admin.initializeApp({
  projectId: 'script-automator-bdbef'
});

async function setAdmin() {
  try {
    const email = 'chaunganpenny@gmail.com';
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log('Successfully set admin claim for', email);
    process.exit(0);
  } catch (error) {
    console.error('Failed:', error);
    process.exit(1);
  }
}

setAdmin();
