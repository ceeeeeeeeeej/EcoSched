import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Admin SDK once
try {
  admin.app();
} catch (e) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

function formatDate(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

async function getTokensForUser(userId: string): Promise<string[]> {
  const tokens: string[] = [];
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  if (userDoc.exists) {
    const u = userDoc.data() as any;
    const arr: unknown = u?.fcmTokens;
    if (Array.isArray(arr)) {
      for (const t of arr) {
        if (typeof t === 'string') tokens.push(t);
      }
    }
  }
  const tSnap = await userRef.collection('tokens').get();
  for (const t of tSnap.docs) {
    const val = t.get('token');
    if (typeof val === 'string') tokens.push(val);
  }
  return Array.from(new Set(tokens));
}

async function sendNotificationToUser(
  userId: string,
  notification: { title: string; body: string },
  data: Record<string, string> = {}
): Promise<void> {
  const tokens = await getTokensForUser(userId);
  if (tokens.length === 0) return;
  await messaging.sendEachForMulticast({ tokens, notification, data });
}

export const sendDailyPickupReminders = functions.pubsub
  .schedule('0 8 * * *') // 08:00 daily
  .timeZone('Asia/Manila')
  .onRun(async () => {
    const today = new Date();
    const todayStr = formatDate(today);

    // Query today's schedules (expects field `pickupDate: YYYY-MM-DD`)
    const snap = await db
      .collection('schedules')
      .where('pickupDate', '==', todayStr)
      .get();

    if (snap.empty) {
      functions.logger.info('No schedules for today');
      return null;
    }

    const allTokensNested = await Promise.all(
      snap.docs.map(async (d) => {
        const s = d.data() as any;
        const uid: string | undefined = s.residentId || s.userId;
        if (!uid) return [] as string[];
        return await getTokensForUser(uid);
      })
    );
    const uniqueTokens = Array.from(new Set(allTokensNested.flat()));
    if (uniqueTokens.length === 0) {
      functions.logger.info('No FCM tokens found for today\'s schedules');
      return null;
    }

    const notif = {
      title: 'Pickup Reminder',
      body: 'Your waste collection is scheduled for today. Please prepare your bins.',
    };

    const res = await messaging.sendEachForMulticast({
      tokens: uniqueTokens,
      notification: notif,
      data: {
        type: 'pickup_reminder',
        date: todayStr,
      },
    });

    functions.logger.info('Reminder sent', { success: res.successCount, failure: res.failureCount });
    return null;
  });

export const sendTestNotification = functions.https.onCall(async (data, context) => {
  const token: string | undefined = data?.token;
  const topic: string | undefined = data?.topic;
  const title: string = data?.title || 'EcoSched Test';
  const body: string = data?.body || 'This is a test notification.';

  if (!token && !topic) {
    throw new functions.https.HttpsError('invalid-argument', 'Provide either token or topic.');
  }

  const message: admin.messaging.Message = {
    notification: { title, body },
    data: { type: 'test' },
    ...(token ? { token } : {}),
    ...(topic ? { topic } : {}),
  } as any;

  const id = await messaging.send(message, true);
  return { messageId: id };
});

export const onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL, emailVerified, providerData } = user;
  const userRef = db.collection('users').doc(uid);
  const doc = await userRef.get();
  if (!doc.exists) {
    await userRef.set({
      uid,
      email: email ?? null,
      displayName: displayName ?? 'New User',
      photoURL: photoURL ?? null,
      emailVerified: !!emailVerified,
      role: 'resident',
      providers: (providerData || []).map((p) => p?.providerId).filter(Boolean),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      active: true,
    });
  } else {
    await userRef.set(
      {
        emailVerified: !!emailVerified,
        providers: (providerData || []).map((p) => p?.providerId).filter(Boolean),
        active: true,
      },
      { merge: true }
    );
  }
});

export const onAuthUserDelete = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;
  const userRef = db.collection('users').doc(uid);
  const tokensSnap = await userRef.collection('tokens').get();
  const batch = db.batch();
  for (const t of tokensSnap.docs) {
    batch.delete(t.ref);
  }
  batch.set(
    userRef,
    {
      active: false,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  await batch.commit();
});

export const onScheduleCreated = functions.firestore
  .document('schedules/{scheduleId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() as any;
    const userId: string | undefined = data?.residentId || data?.userId;
    if (!userId) return;
    const date: string = data?.pickupDate || formatDate(new Date());
    const time: string | undefined = data?.pickupTime;
    const body = `Your waste collection is scheduled on ${date}${time ? ' at ' + time : ''}.`;
    await sendNotificationToUser(userId, { title: 'Pickup Scheduled', body }, {
      type: 'pickup_created',
      scheduleId: context.params.scheduleId,
      date,
      ...(time ? { time } : {}),
    });
  });

export const onScheduleUpdated = functions.firestore
  .document('schedules/{scheduleId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    if (!before || !after) return;
    if (before.status !== after.status && after.status === 'Completed') {
      const userId: string | undefined = after?.residentId || after?.userId;
      if (!userId) return;
      await sendNotificationToUser(
        userId,
        { title: 'Collection Completed', body: 'Your waste was collected successfully. Thank you!' },
        { type: 'pickup_completed', scheduleId: context.params.scheduleId }
      );
    }
  });


