# Firebase Setup Guide for Vorflux

This guide explains the Firebase configuration for the Vorflux Islamic Q&A app.

## Current Live Configuration

**Android is the currently configured live Firebase platform.** The app is registered in Firebase project `ask-quran-ad35f` with Android package name `com.ask.quran`. Other platforms (iOS, web, macOS, Windows, Linux) are not yet registered and will automatically fall back to offline/demo mode at runtime.

## Firebase Console Prerequisites

Before Android Google Sign-In works at runtime, the following **must** be configured in the [Firebase Console](https://console.firebase.google.com/) for project `ask-quran-ad35f`:

> **⚠️ Current status:** The checked-in `google-services.json` contains only a web OAuth client (`client_type: 3`). Google Sign-In on Android requires an Android OAuth client (`client_type: 1`) with registered SHA fingerprints. Until the steps below are completed, Firebase initializes successfully but **Sign in with Google will fail** at runtime.

### 1. Authentication — Google Provider

1. Go to **Authentication** → **Sign-in method**
2. Enable the **Google** provider
3. Set a project support email
4. Click **Save**

### 2. Android SHA Fingerprints for Google Sign-In (Required)

Google Sign-In on Android requires SHA certificate fingerprints registered in the Firebase Console. Without them, the `google-services.json` will not include the Android OAuth client entry needed for sign-in.

1. Obtain your debug SHA-1 fingerprint:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. Go to **Project Settings** → **General** → **Your apps** → the Android app (`com.ask.quran`)
3. Under **SHA certificate fingerprints**, add your debug (and release) SHA-1 and SHA-256 fingerprints
4. Download the **updated** `google-services.json` from the Firebase Console and replace `android/app/google-services.json`
5. Verify the new file contains an `oauth_client` entry with `"client_type": 1` and your `package_name` + `certificate_hash` — this confirms Android sign-in is properly wired

> **Important:** Without completing this step, the app builds and Firebase initializes, but tapping **Sign in with Google** will fail with a Google Sign-In configuration error.

### 3. Cloud Firestore Database

1. Go to **Firestore Database**
2. Click **Create database** (if not already created)
3. Choose your preferred region
4. Start in **test mode** for development, or apply the security rules below for production

### 4. Firestore Composite Index

The app queries user-specific questions sorted by creation time. This requires a composite index:

- **Collection:** `questions`
- **Fields:**
  - `userId` — Ascending
  - `createdAt` — Descending
- **Query scope:** Collection

Create this index in **Firestore Database** → **Indexes** → **Composite** → **Create index**.

> **Tip:** If the index is missing, the app's Firestore queries will fail. The Firebase SDK logs will include a direct URL to create the required index automatically.

## Recommended Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /questions/{questionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Firebase Options

The Android Firebase options in `lib/firebase_options.dart` are configured with the real values from project `ask-quran-ad35f`. Non-Android platforms throw `UnsupportedError`, which the app's `main.dart` catches to activate demo mode.

To add a new platform:
1. Register the platform app in the Firebase Console under project `ask-quran-ad35f`
2. Download the platform-specific config file (if applicable)
3. Add the platform's `FirebaseOptions` in `lib/firebase_options.dart`
4. Update `currentPlatform` to return the new options instead of throwing `UnsupportedError`

## Build and Test

```bash
flutter pub get
flutter build apk --debug
flutter run
```
