const admin = require('firebase-admin');
const serviceAccount = require('./safenow-c7fc7-firebase-adminsdk-fbsvc-5db2f60cba.json');
const fs = require('fs');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function exportCodes() {
  const snapshot = await db.collection('promo_codes').where('isUsed', '==', false).get();
  
  let content = 'BENİ KORUYUN - PROMOSYON KODLARI\n';
  content += '==================================\n';
  content += `Toplam: ${snapshot.docs.length} adet kullanılmamış kod\n`;
  content += `Tarih: ${new Date().toLocaleDateString('tr-TR')}\n`;
  content += '==================================\n\n';
  
  snapshot.docs.forEach((doc, index) => {
    content += `${index + 1}. ${doc.data().code}\n`;
  });

  fs.writeFileSync('kodlar.txt', content, 'utf8');
  console.log(`${snapshot.docs.length} kod kodlar.txt dosyasına yazıldı!`);
  process.exit(0);
}

exportCodes().catch(console.error);
