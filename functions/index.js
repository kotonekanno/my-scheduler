const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();

// This function is triggered by Cloud Scheduler (HTTP).
// Setup Cloud Scheduler to call the endpoint every minute (or 5 minutes).
exports.notifyDueSchedules = functions.https.onRequest(async (req, res) => {
  try {
    // Calculate current time window in UTC (minute precision)
    const now = new Date();
    const minuteStart = new Date(now);
    minuteStart.setSeconds(0, 0);
    const minuteEnd = new Date(minuteStart);
    minuteEnd.setMinutes(minuteEnd.getMinutes() + 1);

    // Query all users (for simplicity), then check schedules.
    // For production, consider query per-user pagination.
    const usersSnap = await db.collection('users').get();
    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const schedulesRef = db.collection('users').doc(userId).collection('schedules');

      // Query schedules with notifyAtUtc between minuteStart and minuteEnd, not disabled, not deleted
      const q = await schedulesRef
        .where('notifyAtUtc', '>=', admin.firestore.Timestamp.fromDate(minuteStart))
        .where('notifyAtUtc', '<', admin.firestore.Timestamp.fromDate(minuteEnd))
        .where('disabled', '==', false)
        .where('deletedAt', '==', null)
        .get();

      if (q.empty) continue;

      // Load user's stored LINE token (assumed stored in users/{userId}/settings token)
      const userSettingsDoc = await db.collection('users').doc(userId).collection('meta').doc('settings').get();
      if (!userSettingsDoc.exists) {
        console.log(`No settings for user ${userId}`);
        continue;
      }
      const settings = userSettingsDoc.data();
      const lineToken = settings ? settings['lineNotifyToken'] : null;
      if (!lineToken) {
        console.log(`No LINE token for user ${userId}`);
        continue;
      }

      for (const doc of q.docs) {
        const data = doc.data();
        const message = data.lineMessage || `${data.title}`;
        // send LINE Notify
        try {
          const resp = await fetch('https://notify-api.line.me/api/notify', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${lineToken}`,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({ message: message })
          });
          if (!resp.ok) {
            console.error(`LINE notify error ${resp.status} for user ${userId}, schedule ${doc.id}`);
          } else {
            console.log(`Sent LINE notify for user ${userId}, schedule ${doc.id}`);
            // mark sent to avoid re-sending: set a sentAt field or use a sent flag
            await doc.ref.update({ sentAt: admin.firestore.FieldValue.serverTimestamp() });
          }
        } catch (e) {
          console.error('LINE send error', e);
        }
      }
    }

    res.status(200).send('ok');
  } catch (err) {
    console.error(err);
    res.status(500).send('error');
  }
});
