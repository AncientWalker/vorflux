# Vorflux

An Islamic Q&A mobile app powered by AI that provides answers exclusively from the **Holy Quran** and **authentic Hadith** collections, with specific citations.

## Features

### Google Sign-In
- Sign in with your Google account to access the app
- User profile stored in Firebase Firestore
- Secure authentication via Firebase Auth

### Ask Tab
- Type any question about Islam
- Get AI-powered answers sourced exclusively from Quran and Hadith
- Every answer includes specific citations
- Questions and answers automatically saved to Firestore

### History Tab
- All your questions and answers synced via Firebase Firestore
- Real-time updates across devices
- Swipe to delete individual entries

### Feed Tab
- Community feed showing real questions from all users
- User names and profile photos displayed
- Real-time updates as new questions are asked

## Tech Stack

- **Framework:** Flutter 3.x with Dart
- **State Management:** Provider
- **Authentication:** Firebase Auth + Google Sign-In
- **Database:** Cloud Firestore
- **AI Backend:** OpenAI Chat Completions API (GPT-4o)
- **UI:** Material Design 3 with custom Islamic theme

## Setup

**Firebase is currently configured for Android only** (package `com.ask.quran`, project `ask-quran-ad35f`). Other platforms automatically fall back to offline/demo mode. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for Firebase Console prerequisites and adding new platforms.

### Quick Start

1. Clone and install dependencies:
   ```bash
   git clone https://github.com/AncientWalker/vorflux.git
   cd vorflux
   flutter pub get
   ```

2. Configure environment:
   ```bash
   cp .env.example .env
   # Edit .env and add your OpenAI API key
   ```

3. Set up Firebase (see [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for Android prerequisites)

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                     # App entry point with Firebase init + auth gate
├── firebase_options.dart         # Firebase configuration
├── models/
│   └── qa_entry.dart             # Q&A data model (with user fields)
├── providers/
│   ├── auth_provider.dart        # Authentication state management
│   ├── history_provider.dart     # History state (Firestore streams)
│   └── feed_provider.dart        # Feed state (Firestore streams)
├── screens/
│   ├── login_screen.dart         # Google Sign-In screen
│   ├── home_screen.dart          # Main tab navigation + sign-out
│   ├── ask_screen.dart           # Ask tab UI
│   ├── history_screen.dart       # History tab UI
│   ├── feed_screen.dart          # Feed tab UI
│   └── detail_screen.dart        # Full Q&A detail view
├── services/
│   ├── auth_service.dart         # Google Sign-In + Firebase Auth
│   ├── firestore_service.dart    # Firestore CRUD operations
│   ├── openai_service.dart       # OpenAI API integration
│   └── database_service.dart     # Legacy SQLite (kept for reference)
├── theme/
│   └── app_theme.dart            # App theme and colors
└── widgets/
    └── loading_indicator.dart    # Islamic-themed loading animation
```

## Firestore Collections

### `users` collection
| Field | Type | Description |
|-------|------|-------------|
| displayName | string | Google display name |
| email | string | Google email |
| photoURL | string | Google profile photo URL |
| createdAt | timestamp | First sign-in |
| lastLoginAt | timestamp | Most recent sign-in |

### `questions` collection
| Field | Type | Description |
|-------|------|-------------|
| userId | string | Firebase Auth UID |
| userName | string | Display name of asker |
| userPhotoURL | string | Profile photo URL of asker |
| questionText | string | The question asked |
| answerText | string | The AI-generated answer |
| createdAt | timestamp | When asked |

## License

MIT
