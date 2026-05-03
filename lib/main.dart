import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/home_screen.dart';
import 'package:vorflux/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const VorfluxApp());
}

class VorfluxApp extends StatelessWidget {
  const VorfluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
        ChangeNotifierProvider(create: (_) => FeedProvider()..loadFeed()),
      ],
      child: MaterialApp(
        title: 'Vorflux',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
