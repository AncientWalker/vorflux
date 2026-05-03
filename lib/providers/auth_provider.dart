import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vorflux/services/auth_service.dart';
import 'package:vorflux/services/firebase_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns true if the user is signed in via Firebase,
  /// OR if Firebase is unavailable (demo mode — treated as "signed in")
  bool get isSignedIn {
    if (!FirebaseConfig.isAvailable) return true;
    return _user != null;
  }

  String get displayName {
    if (!FirebaseConfig.isAvailable) return 'Demo User';
    return _user?.displayName ?? 'Anonymous';
  }

  String get email {
    if (!FirebaseConfig.isAvailable) return 'demo@vorflux.app';
    return _user?.email ?? '';
  }

  String get photoURL {
    if (!FirebaseConfig.isAvailable) return '';
    return _user?.photoURL ?? '';
  }

  String get uid {
    if (!FirebaseConfig.isAvailable) return 'demo-user-001';
    return _user?.uid ?? '';
  }

  AuthProvider() {
    if (FirebaseConfig.isAvailable) {
      AuthService.authStateChanges.listen((User? user) {
        _user = user;
        notifyListeners();
      });
      _user = AuthService.currentUser;
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!FirebaseConfig.isAvailable) {
      _errorMessage = 'Firebase is not configured. Running in demo mode.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signInWithGoogle();
      _user = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (!FirebaseConfig.isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
