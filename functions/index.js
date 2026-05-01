const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

// ── Bildirim Gönderme ──
exports.sendNotification = onDocumentCreated("notifications/{notifId}", async (event) => {
    const data = event.data.data();
    
    const token = data.token;
    const title = data.title;
    const body = data.body;
    const type = data.type;
    const senderUserId = data.senderUserId || '';
    const senderName = data.senderName || '';

    if (!token) return null;

    let sound = 'guvendeyim';
    if (type === 'panic') sound = 'acil';
    else if (type === 'audio') sound = 'seskaydi';

    const message = {
      token: token,
      notification: { title: title, body: body },
      data: { type: type, senderUserId: senderUserId, senderName: senderName },
      android: {
        notification: {
          sound: sound,
          priority: 'high',
          channelId: type === 'panic' ? 'acil' : (type === 'audio' ? 'seskaydi' : 'guvendeyim'),
        },
        priority: 'high',
      },
    };
    
    try {
      await admin.messaging().send(message);
      console.log("Bildirim gönderildi:", token);
    } catch (error) {
      console.error("Bildirim hatası:", error);
    }
    
    return null;
});

// ── Otomatik Ses Kaydı Silme (Her saat çalışır) ──
exports.deleteExpiredAudio = onSchedule("every 1 hours", async () => {
  const db      = admin.firestore();
  const storage = admin.storage().bucket();
  const now     = Date.now();

  // panic_events koleksiyonundaki ses kayıtlarını tara
  const snap = await db.collection("panic_events").get();

  const deletePromises = [];

  for (const doc of snap.docs) {
    const data = doc.data();

    // Ses kaydı değilse atla
    if (!data.audioUrl) continue;

    // Kaydın zamanı
    const ts = data.timestamp;
    if (!ts) continue;
    const recordedAt = ts.toDate ? ts.toDate().getTime() : new Date(ts).getTime();

    // Ses kaydı Premium'a özel — her zaman 24 saat sakla
    const limitMs = 24 * 60 * 60 * 1000;
    const ageMs   = now - recordedAt;

    if (ageMs >= limitMs) {
      console.log(`Siliniyor: ${doc.id} (${Math.floor(ageMs/3600000)} saat geçmiş)`);

      // 1. Storage'daki ses dosyasını sil
      if (data.audioUrl) {
        try {
          const url      = decodeURIComponent(data.audioUrl);
          const match    = url.match(/\/o\/(.+?)\?/);
          if (match) {
            const filePath = match[1];
            deletePromises.push(
              storage.file(filePath).delete().catch(e => console.warn("Storage sil hatası:", e))
            );
          }
        } catch (e) {
          console.warn("URL parse hatası:", e);
        }
      }

      // 2. Firestore kaydını sil
      deletePromises.push(
        db.collection("panic_events").doc(doc.id).delete()
          .catch(e => console.warn("Firestore sil hatası:", e))
      );

      // 3. received_audio koleksiyonundan da sil
      try {
        const audioSnap = await db.collection("received_audio")
          .where("panicEventId", "==", doc.id).get();
        audioSnap.forEach(d => {
          deletePromises.push(d.ref.delete().catch(e => console.warn(e)));
        });
      } catch (e) {}
    }
  }

  await Promise.all(deletePromises);
  console.log(`Silme tamamlandı. ${deletePromises.length} işlem yapıldı.`);
  return null;
});
