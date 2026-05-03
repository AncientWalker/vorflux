# Vorflux ✨

An Islamic Q&A mobile app powered by AI that provides answers exclusively from the **Holy Quran** and **authentic Hadith** collections, with specific citations.

## Features

### 📖 Ask Tab
- Type any question about Islam
- Get AI-powered answers sourced exclusively from Quran and Hadith
- Every answer includes specific citations (Surah:Ayah for Quran, collection name and number for Hadith)
- Beautiful Markdown-formatted responses
- Suggested questions to get started

### 📚 History Tab
- All your questions and answers saved locally on device
- Swipe to delete individual entries
- Tap to view full question and answer
- Clear all history option

### 👥 Feed Tab
- Community feed showing questions from other users
- Sample/mock data demonstrating the feed concept
- Pull-to-refresh functionality
- Ready for backend integration

## Tech Stack

- **Framework:** Flutter 3.x with Dart
- **State Management:** Provider
- **AI Backend:** OpenAI Chat Completions API (GPT-4o)
- **Local Storage:** SQLite (sqflite)
- **UI:** Material Design 3 with custom Islamic theme (greens, golds, elegant typography)
- **Fonts:** Google Fonts (Playfair Display + Nunito Sans)

## Setup

### Prerequisites
- Flutter SDK 3.8+
- Android SDK / Xcode (for running on device/emulator)
- An OpenAI API key

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/AncientWalker/vorflux.git
   cd vorflux
   ```

2. Copy the environment file and add your API key:
   ```bash
   cp .env.example .env
   # Edit .env and replace 'your_api_key_here' with your actual OpenAI API key
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Configuration

The app uses a `.env` file for configuration:

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | Your OpenAI API key (required for the Ask tab) |

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── models/
│   └── qa_entry.dart          # Q&A data model
├── providers/
│   ├── history_provider.dart  # History state management
│   └── feed_provider.dart     # Feed state management
├── screens/
│   ├── home_screen.dart       # Main tab navigation
│   ├── ask_screen.dart        # Ask tab UI
│   ├── history_screen.dart    # History tab UI
│   ├── feed_screen.dart       # Feed tab UI
│   └── detail_screen.dart     # Full Q&A detail view
├── services/
│   ├── openai_service.dart    # OpenAI API integration
│   └── database_service.dart  # SQLite database operations
├── theme/
│   └── app_theme.dart         # App theme and colors
└── widgets/
    └── loading_indicator.dart # Islamic-themed loading animation
```

## Important Note

⚠️ **Always verify citations with scholarly sources.** AI responses may contain inaccuracies. This app is a tool for learning and exploration, not a replacement for qualified Islamic scholarship.

## License

MIT
