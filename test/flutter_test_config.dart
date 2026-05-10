// Flutter test configuration file.
// Runs before every test in this directory.
// Bootstraps sqflite FFI so that DatabaseService can be used in unit/widget tests
// on desktop (Linux/macOS/Windows) where the native sqflite plugin is unavailable.

import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Initialise sqflite FFI (uses a native C library instead of the Android plugin)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
