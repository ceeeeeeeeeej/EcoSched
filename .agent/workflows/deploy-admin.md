---
description: Deploy the Admin Dashboard to Firebase Hosting
---

# Deploy Admin Dashboard Workflow

This workflow will guide you through deploying the EcoSched Admin Dashboard to Firebase Hosting.

## Prerequisites

Before you begin, ensure you have:
- ✅ Node.js installed (v16 or higher)
- ✅ Firebase CLI installed (`npm install -g firebase-tools`)
- ✅ Firebase project setup with Authentication & Firestore enabled
- ✅ Updated Firebase config in `Admin_Dashboard/config/firebase.js`

## Deployment Steps

### Step 1: Navigate to Admin Dashboard Directory

```cmd
cd "c:\4th Year 1st Semester\Thesis 1\echoshedv2\Admin_Dashboard"
```

### Step 2: Install Dependencies (if not already done)

```cmd
npm install
```

### Step 3: Build the Project

This will create an optimized production build in the `dist` folder:

```cmd
npm run build
```

Or build directly with Node:

```cmd
node build.js
```

### Step 4: Login to Firebase (if not already logged in)

```cmd
firebase login
```

This will open a browser window for authentication. Follow the prompts to sign in with your Google account.

### Step 5: Verify Firebase Project

Check that you're using the correct Firebase project:

```cmd
firebase projects:list
```

If needed, select your project:

```cmd
firebase use <your-project-id>
```

### Step 6: Test Locally (Optional but Recommended)

Before deploying to production, test the build locally:

```cmd
firebase serve --port 3000
```

Visit `http://localhost:3000` in your browser to test. Press `Ctrl+C` to stop the server when done.

### Step 7: Deploy to Firebase Hosting

Deploy only the hosting (Admin Dashboard):

```cmd
firebase deploy --only hosting
```

Or deploy both hosting and Firestore rules:

```cmd
firebase deploy
```

### Step 8: Verify Deployment

After deployment completes, you'll see a hosting URL like:
- `https://your-project-id.web.app`
- `https://your-project-id.firebaseapp.com`

Visit the URL to verify your admin dashboard is live.

## Quick Deploy (All-in-One Command)

For subsequent deployments, you can use the npm script:

```cmd
npm run deploy:hosting
```

This will:
1. Build the project (run `node build.js`)
2. Deploy to Firebase hosting

## Alternative: Use the Deployment Script

You can also use the included deployment script:

```cmd
deploy.bat
```

This interactive script will:
- Check for Firebase CLI installation
- Verify Firebase authentication
- Install dependencies if needed
- Optionally test locally before deploying
- Deploy to Firebase Hosting
- Deploy Firestore rules

## Troubleshooting

### Build Fails
- Ensure all required files exist in `html/`, `css/`, `js/`, and `config/` directories
- Check the `build.js` file for the list of files being processed

### Firebase Login Issues
- Clear your Firebase cache: `firebase logout` then `firebase login` again
- Check your internet connection
- Verify you're using the correct Google account

### Deployment Fails
- Verify your `firebase.json` configuration is correct
- Ensure the `dist` folder exists and contains the built files
- Check Firebase Console for any project-level issues

### 404 Errors After Deployment
- Verify `index.html` exists in the `dist` folder
- Check the `public` setting in `firebase.json` (should be `"dist"`)
- Clear your browser cache and try again

## Post-Deployment Checklist

After successful deployment:
- ✅ Test user registration and login
- ✅ Verify all dashboard pages load correctly
- ✅ Test Firebase authentication integration
- ✅ Check Firestore data operations
- ✅ Monitor Firebase Console for errors
- ✅ Test on different browsers and devices

## Useful Commands

```cmd
# View deployment history
firebase hosting:channel:list

# Rollback to previous version (if needed)
firebase hosting:channel:deploy previous-version

# View logs
firebase functions:log

# Check project info
firebase projects:list
```

---

🎉 **Your Admin Dashboard should now be live!**
