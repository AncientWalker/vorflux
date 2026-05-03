# Firebase Setup Guide for Vorflux

This guide explains how to complete the Firebase setup for the Vorflux Islamic Q&A app.

## Prerequisites

- A Google account
- Access to [Firebase Console](https://console.firebase.google.com/)
- Flutter CLI installed

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "Vorflux" (or any name you prefer)
4. Enable/disable Google Analytics as you prefer
5. Click "Create project"

## Step 2: Enable Authentication

1. In the Firebase Console, go to **Authentication** → **Sign-in method**
2. Click **Google** provider
3. Toggle it to **Enabled**
4. Set a project support email
5. Click **Save**

## Step 3: Enable Cloud Firestore

1. In the Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select your preferred region
5. Click **Enable**

### Recommended Firestore Security Rules

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

### Required Firestore Index

Create a composite index for the `questions` collection:
- Collection: `questions`
- Fields: `userId` (Ascending), `createdAt` (Descending)
- Query scope: Collection

## Step 4: Register Android App

1. In Firebase Console, click the **Android** icon to add an Android app
2. Package name: `com.vorflux.vorflux`
3. App nickname: `Vorflux Android`
4. Get SHA-1 fingerprint: `cd android && ./gradlew signingReport`
5. Download `google-services.json` and replace `android/app/google-services.json`

## Step 5: Update Firebase Options

Run `flutterfire configure --project=YOUR_PROJECT_ID` or manually edit `lib/firebase_options.dart`.

## Step 6: Build and Test

```bash
flutter pub get
flutter build apk --debug
flutter run
```
