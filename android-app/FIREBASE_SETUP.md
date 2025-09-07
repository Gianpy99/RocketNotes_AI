# Firebase Setup Guide for RocketNotes AI

## 🔑 Getting Firebase API Keys

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select existing project
3. Follow the setup wizard

### Step 2: Get API Keys from Firebase Console

#### For Web App:
1. Go to **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Click **Add app** → **Web app** (</>) icon
4. Register your app with name "RocketNotes AI Web"
5. Copy the config values from the `firebaseConfig` object:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",           // ← FIREBASE_API_KEY
  authDomain: "your-project.firebaseapp.com",  // ← FIREBASE_AUTH_DOMAIN
  projectId: "your-project-id",   // ← FIREBASE_PROJECT_ID
  storageBucket: "your-project.appspot.com",   // ← FIREBASE_STORAGE_BUCKET
  messagingSenderId: "123456789", // ← FIREBASE_MESSAGING_SENDER_ID
  appId: "1:123:web:abc123..."    // ← FIREBASE_APP_ID
};
```

#### For Android App:
1. In the same **Project Settings** → **Your apps**
2. Click **Add app** → **Android** icon
3. Enter package name: `com.example.pensieve`
4. Copy the values from Android config

## 📝 Configuration Setup

### Step 1: Fill in .env file
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and paste your Firebase values:
   ```env
   FIREBASE_API_KEY=AIzaSyC_your_actual_api_key_here
   FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=123456789012
   FIREBASE_APP_ID=1:123456789012:web:abcdef123456

   FIREBASE_ANDROID_API_KEY=AIzaSyC_your_android_api_key
   FIREBASE_ANDROID_APP_ID=1:123456789012:android:abcdef123456
   ```

### Step 2: Download Firebase Config Files

#### For Android:
1. In Firebase Console → Project Settings → Your apps
2. Download `google-services.json`
3. Place it in: `android-app/android/app/google-services.json`

#### For iOS (if needed):
1. Download `GoogleService-Info.plist`
2. Place it in: `android-app/ios/Runner/GoogleService-Info.plist`

### Step 3: Clean and Rebuild (Important!)
After changing the package name, you must clean and rebuild:

```bash
# Use the provided script
.\rebuild-after-rename.ps1

# Or manually:
flutter clean
flutter pub get
flutter build apk --debug
```

### Step 4: Firebase Gradle Configuration (Auto-Configured!)
✅ **Already Done!** I've automatically configured:

**Project-level build.gradle.kts:**
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.3" apply false
}
```

**App-level build.gradle.kts:**
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    // Firebase BoM for compatible versions
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))

    // Firebase SDKs
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-analytics")
}
```

### Step 5: Rebuild with Firebase
```bash
# Use the new script for Firebase rebuild
.\rebuild-firebase.ps1
```

## 🚀 Running the App

### Development (with Firebase):
```bash
# Use the provided script
.\run-with-firebase.ps1
```

### Manual run:
```bash
flutter run --dart-define=FIREBASE_API_KEY=your_key_here --dart-define=FIREBASE_PROJECT_ID=your_project_id --dart-define=FIREBASE_APP_ID=your_app_id
```

### Building for Release:
```bash
# Debug APK
.\build-with-firebase.ps1 -BuildType debug

# Release APK
.\build-with-firebase.ps1 -BuildType release

# App Bundle for Play Store
.\build-with-firebase.ps1 -BuildType appbundle
```

## 🔒 Security Notes

- ✅ **DO NOT** commit `.env` file to version control
- ✅ **DO NOT** share API keys publicly
- ✅ `.env` is already in `.gitignore`
- ✅ Use different Firebase projects for dev/staging/production
- ✅ Enable Firebase Security Rules for data protection

## 🐛 Troubleshooting

### "Firebase not configured" error:
- Check that `.env` file exists and contains valid values
- Ensure you're using the run/build scripts that pass the environment variables
- Verify Firebase project is active in Firebase Console

### Build fails:
- Check that `google-services.json` is in the correct location
- Verify package name matches Firebase configuration
- Ensure all required dependencies are installed

### Authentication issues:
- Check Firebase Authentication is enabled in Firebase Console
- Verify the correct API keys are being used
- Check Firebase Security Rules allow your operations

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.google.com/docs/flutter/setup)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/build#build-environment)
