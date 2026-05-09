import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/firebase_options.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/home_screen.dart';
import 'package:vorflux/screens/login_screen.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Try to initialize Firebase, but don't crash if credentials are invalid
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseConfig.setAvailable(true);
    debugPrint('[Vorflux] Firebase initialized successfully');
  } catch (e) {
    FirebaseConfig.setAvailable(false);
    debugPrint('[Vorflux] Firebase unavailable, running in offline/demo mode: $e');
  }

  runApp(const VorfluxApp());
}

class VorfluxApp extends StatelessWidget {
  const VorfluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: MaterialApp(
        title: 'Ask Quran',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase is not available, skip login and go straight to the app
    if (!FirebaseConfig.isAvailable) {
      return const HomeScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isSignedIn) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
