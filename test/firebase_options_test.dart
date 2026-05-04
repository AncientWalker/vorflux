import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    tearDown(() {
      // Reset the platform override after each test.
      debugDefaultTargetPlatformOverride = null;
    });

    group('currentPlatform', () {
      test('returns android config on Android', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final options = DefaultFirebaseOptions.currentPlatform;
        expect(options, DefaultFirebaseOptions.android);
      });

      test('throws UnsupportedError on iOS', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('iOS'),
          )),
        );
      });

      test('throws UnsupportedError on macOS', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('macOS'),
          )),
        );
      });

      test('throws UnsupportedError on Windows', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Windows'),
          )),
        );
      });

      test('throws UnsupportedError on Linux', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        expect(
          () => DefaultFirebaseOptions.currentPlatform,
          throwsA(isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Linux'),
          )),
        );
      });
    });
  });
}
