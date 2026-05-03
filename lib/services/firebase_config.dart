/// Tracks whether Firebase was successfully initialized.
/// When Firebase is unavailable (e.g., placeholder credentials),
/// the app falls back to local SQLite storage and skips authentication.
class FirebaseConfig {
  static bool _isAvailable = false;

  static bool get isAvailable => _isAvailable;

  static void setAvailable(bool value) {
    _isAvailable = value;
  }
}
