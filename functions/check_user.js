const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'script-automator-bdbef'
});

const db = admin.firestore();
const uid = 'RS6qcaXCQFgANCXsBroBELIIrwk1';

async function run() {
  const userRef = db.collection('users').doc(uid);
  const doc = await userRef.get();
  if (!doc.exists) {
    console.log(`User ${uid} does not exist in Firestore.`);
  } else {
    console.log(`User ${uid} data:`, doc.data());
    if (doc.data().is_banned) {
      console.log('User is banned! Unbanning...');
      await userRef.update({ is_banned: false });
      console.log('User has been unbanned.');
    } else {
      console.log('User is not banned in Firestore.');
    }
  }
  process.exit(0);
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});
