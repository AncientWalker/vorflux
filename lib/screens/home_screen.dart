import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/screens/ask_screen.dart';
import 'package:vorflux/screens/feed_screen.dart';
import 'package:vorflux/screens/history_screen.dart';
import 'package:vorflux/screens/saved_screen.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    _screens = [
      const AskScreen(),
      HistoryScreen(onOpenThread: () => setState(() => _currentIndex = 0)),
      const FeedScreen(),
      const SavedScreen(),
    ];
    super.initState();
    final authProvider = context.read<AuthProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryProvider>().listenToUserThreads(
            userId: authProvider.uid,
            userName: authProvider.displayName,
            userPhotoURL: authProvider.photoURL,
          );
      context.read<FeedProvider>().listenToFeed();
      context.read<BookmarkProvider>().listenToBookmarks(authProvider.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 24),
            const SizedBox(width: 8),
            const Text('Vorflux'),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New conversation',
              onPressed: () {
                context.read<HistoryProvider>().startNewThread();
              },
            ),
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAboutDialog(context),
            ),
          if (FirebaseConfig.isAvailable && authProvider.isSignedIn)
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'signout') _handleSignOut(context, authProvider);
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.displayName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        authProvider.email,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  backgroundImage: authProvider.photoURL.isNotEmpty
                      ? NetworkImage(authProvider.photoURL)
                      : null,
                  child: authProvider.photoURL.isEmpty
                      ? Text(
                          authProvider.displayName.isNotEmpty
                              ? authProvider.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          if (!FirebaseConfig.isAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: const Text(
                  'Demo',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: AppColors.goldDark,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer_outlined),
              activeIcon: Icon(Icons.question_answer),
              label: 'Ask',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<HistoryProvider>().stopListening();
      context.read<FeedProvider>().stopListening();
      context.read<BookmarkProvider>().stopListening();
      await authProvider.signOut();
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('About Vorflux', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vorflux is an Islamic Q&A app that provides answers exclusively from the Holy Quran and authentic Hadith collections.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Powered by AI, every answer cites specific Surah:Ayah references for Quran verses and Hadith collection names with numbers.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.goldDark, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always verify citations with scholarly sources. AI can make mistakes.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (!FirebaseConfig.isAvailable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: AppColors.goldDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Running in demo mode. Data is stored locally.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.goldDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
