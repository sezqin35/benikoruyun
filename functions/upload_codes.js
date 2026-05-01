const admin = require('firebase-admin');
const serviceAccount = require('./safenow-c7fc7-firebase-adminsdk-fbsvc-5db2f60cba.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 13; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

async function uploadCodes() {
  const codes = new Set();
  while (codes.size < 1000) {
    codes.add(generateCode());
  }

  const batch = db.batch();
  let count = 0;

  for (const code of codes) {
    const ref = db.collection('promo_codes').doc(code);
    batch.set(ref, {
      code: code,
      isUsed: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      usedBy: null,
      usedAt: null,
    });
    count++;

    // Firestore batch limiti 500
    if (count % 500 === 0) {
      await batch.commit();
      console.log(`${count} kod yüklendi...`);
    }
  }

  await batch.commit();
  console.log('1000 kod başarıyla yüklendi!');
  process.exit(0);
}

uploadCodes().catch(console.error);
