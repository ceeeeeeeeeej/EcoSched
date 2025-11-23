1# EcoSched Firebase Functions

This folder contains Cloud Functions for EcoSched.

Setup:
- Install firebase-tools, login, select your project
- Install dependencies in functions/, then deploy

Commands:
- npm i -g firebase-tools
- firebase login
- firebase use --add
- cd functions && npm install && npm run build
- cd .. && firebase deploy --only functions

Included:
- sendDailyPickupReminders (scheduled, 08:00 Asia/Manila)
- sendTestNotification (callable)
- onAuthUserCreate (Auth trigger: create/merge user profile)
- onAuthUserDelete (Auth trigger: cleanup tokens, mark inactive)
- onScheduleCreated (Firestore trigger: notify user on new schedule)
1- onScheduleUpdated (Firestore trigger: notify when status changes to Completed)
