# 🚀 Deployment Guide - Fixed Schedule System

## Step 1: Deploy Firestore Rules ✅

```bash
cd "c:\4th Year 1st Semester\Thesis 1\echoshedv2\Admin_Dashboard"
firebase deploy --only firestore:rules
```

**Expected Output:**
```
✔ Deploy complete!
Project Console: https://console.firebase.google.com/project/...
```

---

## Step 2: Initialize Fixed Schedules in Firestore

### Option A: Using Firebase Console (Recommended)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database**
4. Press `F12` to open browser Developer Tools
5. Go to **Console** tab
6. Copy and paste this code:

```javascript
const db = firebase.firestore();

// Victoria - Monday & Tuesday
db.collection('area_schedules').add({
  area: 'victoria',
  scheduleName: 'Victoria Waste Collection',
  days: ['monday', 'tuesday'],
  time: '08:00',
  endTime: '10:00',
  recurring: true,
  active: true,
  createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp()
}).then(() => console.log('✅ Victoria schedule created!'));

// Dayo-an - Saturday
db.collection('area_schedules').add({
  area: 'dayo-an',
  scheduleName: 'Dayo-an Waste Collection',
  days: ['saturday'],
  time: '08:00',
  endTime: '10:00',
  recurring: true,
  active: true,
  createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  updatedAt: firebase.firestore.FieldValue.serverTimestamp()
}).then(() => console.log('✅ Dayo-an schedule created!'));
```

7. Press Enter
8. **Expected**: See ✅ messages in console

### Option B: Manual Creation in Firestore

1. Go to Firestore Database
2. Click **Start collection**
3. Collection ID: `area_schedules`
4. Add documents manually with the fields shown above

---

## Step 3: Verify Fixed Schedules

1. In Firestore Console, check `area_schedules` collection
2. Should see 2 documents:
   - One for Victoria (days: monday, tuesday)
   - One for Dayo-an (days: saturday)

---

## Step 4: Run Flutter App

```bash
cd "c:\4th Year 1st Semester\Thesis 1\echoshedv2"
flutter pub get
flutter run
```

---

## Step 5: Test the System

### Test on Resident App:

1. **Login as Victoria resident** (user's barangay = "victoria")
   - Dashboard shows "Upcoming Collection" card
   - Next Monday or Tuesday displayed
   - Countdown shows days until collection

2. **Login as Dayo-an resident** (user's barangay = "dayo-an")
   - Dashboard shows upcoming Saturday collection

### Test on Admin Dashboard:

1. Open `Admin_Dashboard/html/schedules.html`
2. Should see:
   - Blue "FIXED SCHEDULE" badge on Victoria/Dayo-an entries
   - Info message: "This is a fixed recurring schedule"
   - Calendar shows recurring pattern

---

## Step 6: Test Notifications (Optional)

### Method 1: Change Device Time
1. Set phone/emulator to 1 day before next collection
2. Wait 1 minute
3. Should receive notification: "Collection Tomorrow!"

### Method 2: Wait for Real Notification
- Notification will arrive automatically 1 day before scheduled collection

---

## ✅ Deployment Checklist

- [ ] Firestore rules deployed
- [ ] Fixed schedules created in Firestore (Victoria + Dayo-an)
- [ ] Flutter app running
- [ ] Victoria residents see Mon/Tue schedule
- [ ] Dayo-an residents see Sat schedule
- [ ] Dashboard shows upcoming collection card
- [ ] Admin dashboard shows "FIXED SCHEDULE" badge
- [ ] (Optional) Test notification received

---

## 🔧 Troubleshooting

### Issue: No upcoming collection card shows

**Solution:**
- Check user's `barangay` field in Firestore users collection
- Must be exactly "victoria" or "dayo-an" (lowercase)
- Check that `area_schedules` documents exist and `active: true`

### Issue: No notifications

**Solution:**
- Ensure app has notification permissions
- Check that flutter_local_notifications is in pubspec.yaml
- Restart app after granting permissions

### Issue: Admin doesn't see schedules

**Solution:**
- Check that `collection_schedules` collection has entries
- Schedules auto-generate from `area_schedules` in the app
- Try creating a manual schedule for the area

---

## 📊 Expected Results

### Victoria Residents See:
- Collections every **Monday** and **Tuesday** at 8:00 AM
- Upcoming collection card on dashboard
- Reminder notification day before

### Dayo-an Residents See:
- Collection every **Saturday** at 8:00 AM
- Upcoming collection card on dashboard
- Reminder notification day before

### Admin Sees:
- Fixed schedule badges
- Auto-generated weekly entries
- Can reschedule specific dates with reason

---

## 🎉 You're Done!

The system is now live and will:
- ✅ Automatically generate schedules for next 4 weeks
- ✅ Send reminders 1 day before collection
- ✅ Show upcoming collection on dashboard
- ✅ Alert residents when schedules are rescheduled

No manual schedule creation needed for Victoria and Dayo-an! 🎊
