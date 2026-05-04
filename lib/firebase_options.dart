import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static Never _unsupported(String platform) => throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for $platform. '
        'Add a $platform app in the Firebase Console and update this file.',
      );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      _unsupported('web');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        _unsupported('iOS');
      case TargetPlatform.macOS:
        _unsupported('macOS');
      case TargetPlatform.windows:
        _unsupported('Windows');
      case TargetPlatform.linux:
        _unsupported('Linux');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-XLsJvNLfwHKrlDDq165nZvVWXrgPh3E',
    appId: '1:972574497061:android:9bd7563fb1398d6eb022cc',
    messagingSenderId: '972574497061',
    projectId: 'ask-quran-ad35f',
    storageBucket: 'ask-quran-ad35f.firebasestorage.app',
  );
}
