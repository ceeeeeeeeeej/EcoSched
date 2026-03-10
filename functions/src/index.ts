import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const cors = require('cors')({ origin: true });

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

function buildStatusNotification(
  status: string,
  date?: string,
  time?: string
): { title: string; body: string } {
  const when = date ? `${date}${time ? ' at ' + time : ''}` : undefined;

  switch (status) {
    case 'Scheduled':
      return {
        title: 'Pickup Scheduled',
        body: when
          ? `Your waste collection is scheduled on ${when}.`
          : 'Your waste collection has been scheduled.',
      };
    case 'On The Way':
    case 'On Route':
    case 'Collector On The Way':
      return {
        title: 'Collector On The Way',
        body: when
          ? `Your collector is on the way for your pickup on ${when}.`
          : 'Your collector is on the way for your scheduled pickup.',
      };
    case 'Near':
    case 'Arriving Soon':
      return {
        title: 'Collector Nearby',
        body:
          'Your collector is near your location. Please prepare your waste bins.',
      };
    case 'In Progress':
      return {
        title: 'Collection In Progress',
        body: 'Your waste collection is currently in progress.',
      };
    case 'Completed':
      return {
        title: 'Collection Completed',
        body: 'Your waste was collected successfully. Thank you!',
      };
    case 'Cancelled':
    case 'Canceled':
      return {
        title: 'Collection Cancelled',
        body: when
          ? `Your waste collection scheduled on ${when} has been cancelled.`
          : 'Your waste collection has been cancelled.',
      };
    default:
      return {
        title: 'Collection Update',
        body: when
          ? `Your collection status is now "${status}" for the pickup on ${when}.`
          : `Your collection status is now "${status}".`,
      };
  }
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

    if (before.status === after.status || typeof after.status !== 'string') {
      return;
    }

    const userId: string | undefined = after?.residentId || after?.userId;
    if (!userId) return;

    const scheduleId: string = context.params.scheduleId;
    const date: string | undefined = after?.pickupDate;
    const time: string | undefined = after?.pickupTime;
    const status: string = after.status;

    const notification = buildStatusNotification(status, date, time);
    const isCompleted = status === 'Completed';

    await sendNotificationToUser(userId, notification, {
      type: isCompleted ? 'pickup_completed' : 'pickup_status_updated',
      scheduleId,
      status,
      ...(date ? { date } : {}),
      ...(time ? { time } : {}),
    });
  });

function buildServiceAreaTopic(rawArea: unknown): string | null {
  if (typeof rawArea !== 'string') return null;
  const value = rawArea.trim().toLowerCase();
  if (!value) return null;
  const cleaned = value.replace(/[^a-z0-9]+/g, '_');
  const suffix = cleaned || 'general';
  return `area_${suffix}`;
}

export const onCollectionScheduleCreated = functions.firestore
  .document('collection_schedules/{scheduleId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() as any;
    const topic = buildServiceAreaTopic(data?.serviceArea ?? data?.area);
    if (!topic) {
      functions.logger.info('No valid serviceArea for schedule', {
        id: context.params.scheduleId,
      });
      return;
    }

    const rawDate: unknown = data?.scheduledDate ?? data?.startDate;
    let dateStr: string | undefined;
    if (rawDate instanceof admin.firestore.Timestamp) {
      dateStr = formatDate(rawDate.toDate());
    } else if (rawDate instanceof Date) {
      dateStr = formatDate(rawDate);
    } else if (typeof rawDate === 'string' && rawDate.length >= 10) {
      dateStr = rawDate.slice(0, 10);
    }

    const timeStr: string | undefined = typeof data?.startTime === 'string'
      ? data.startTime
      : undefined;

    const scheduleName: string =
      (data?.name ?? data?.scheduleName ?? 'Waste collection schedule').toString();

    const notif = {
      title: 'New Collection Schedule',
      body:
        dateStr && timeStr
          ? `${scheduleName} set on ${dateStr} at ${timeStr}.`
          : dateStr
            ? `${scheduleName} set on ${dateStr}.`
            : `${scheduleName} has been scheduled in your area.`,
    };

    await messaging.send({
      topic,
      notification: notif,
      data: {
        type: 'area_schedule_created',
        scheduleId: context.params.scheduleId,
        serviceArea: String(data?.serviceArea ?? data?.area ?? ''),
        ...(dateStr ? { date: dateStr } : {}),
        ...(timeStr ? { time: timeStr } : {}),
      },
    });

    functions.logger.info('Area schedule notification sent', {
      scheduleId: context.params.scheduleId,
      topic,
    });
  });

export const sendAreaCollectionReminders = functions.pubsub
  .schedule('0 7 * * *') // 07:00 daily
  .timeZone('Asia/Manila')
  .onRun(async () => {
    const today = new Date();
    const todayStr = formatDate(today);

    const snap = await db.collection('collection_schedules').get();
    if (snap.empty) {
      functions.logger.info('No collection_schedules documents found');
      return null;
    }

    type ReminderGroup = {
      topic: string;
      timeStr?: string;
      scheduleName: string;
      count: number;
    };

    const groups = new Map<string, ReminderGroup>();

    snap.forEach((doc) => {
      const data = doc.data() as any;
      const topic = buildServiceAreaTopic(data?.serviceArea ?? data?.area);
      if (!topic) {
        return;
      }

      const rawDate: unknown = data?.scheduledDate ?? data?.startDate;
      let dateStr: string | undefined;
      if (rawDate instanceof admin.firestore.Timestamp) {
        dateStr = formatDate(rawDate.toDate());
      } else if (rawDate instanceof Date) {
        dateStr = formatDate(rawDate);
      } else if (typeof rawDate === 'string' && rawDate.length >= 10) {
        dateStr = rawDate.slice(0, 10);
      }

      if (dateStr !== todayStr) {
        return;
      }

      const timeStr: string | undefined =
        typeof data?.startTime === 'string' ? data.startTime : undefined;

      const scheduleName: string =
        (data?.name ??
          data?.scheduleName ??
          'Waste collection schedule').toString();

      const key = `${topic}|${timeStr ?? ''}`;
      const existing = groups.get(key);
      if (existing) {
        existing.count += 1;
        return;
      }

      groups.set(key, {
        topic,
        timeStr,
        scheduleName,
        count: 1,
      });
    });

    if (groups.size === 0) {
      functions.logger.info('No collection schedules for today');
      return null;
    }

    const results = await Promise.all(
      Array.from(groups.values()).map(async (group) => {
        const { topic, timeStr, scheduleName, count } = group;
        const bodyBase =
          timeStr && timeStr.length > 0
            ? `${scheduleName} in your area is scheduled today at ${timeStr}.`
            : `${scheduleName} in your area is scheduled for today.`;

        const body =
          count > 1
            ? `${bodyBase} There are multiple collection points in your area today. Please prepare your garbage.`
            : `${bodyBase} Please prepare your garbage.`;

        const message: admin.messaging.Message = {
          topic,
          notification: {
            title: 'Garbage Collection Reminder',
            body,
          },
          data: {
            type: 'area_pickup_reminder',
            date: todayStr,
            ...(timeStr ? { time: timeStr } : {}),
          },
        } as any;

        return messaging.send(message);
      })
    );

    functions.logger.info('Area collection reminders sent', {
      count: results.length,
    });

    return null;
  });

export const notifyBarangay = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { barangay, title, body, type } = req.body.data || req.body;

      if (!barangay || !title || !body) {
        res.status(400).send({ error: 'Missing required fields: barangay, title, body' });
        return;
      }

      const topic = buildServiceAreaTopic(barangay);
      if (!topic) {
        res.status(400).send({ error: 'Invalid barangay name' });
        return;
      }

      const message: admin.messaging.Message = {
        topic,
        notification: { title, body },
        data: {
          type: type || 'general_notification',
          barangay,
        },
      };

      const response = await messaging.send(message);
      functions.logger.info('Push sent to topic', { topic, messageId: response });
      res.status(200).send({ success: true, messageId: response });
    } catch (error) {
      functions.logger.error('Error sending barangay notification', error);
      res.status(500).send({ error: 'Failed to send notification' });
    }
  });
});
