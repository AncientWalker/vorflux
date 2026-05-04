import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/bookmark_provider.dart';
import 'package:vorflux/theme/app_theme.dart';

class BookmarkToggleButton extends StatelessWidget {
  const BookmarkToggleButton({
    super.key,
    required this.thread,
    this.iconSize = 24,
    this.showLabel = false,
    this.showSnackBar = true,
    this.padding = EdgeInsets.zero,
    this.activeColor = AppColors.gold,
    this.inactiveColor = AppColors.textHint,
  });

  final ConversationThread thread;
  final double iconSize;
  final bool showLabel;
  final bool showSnackBar;
  final EdgeInsetsGeometry padding;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isBookmarked(thread.id);
        final icon = Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
          size: iconSize,
          color: isBookmarked ? activeColor : inactiveColor,
        );

        if (showLabel) {
          return GestureDetector(
            onTap: () => _onToggle(context, bookmarkProvider, isBookmarked),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    isBookmarked ? 'Saved' : 'Save',
                    style: TextStyle(
                      fontSize: 12,
                      color: isBookmarked ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return IconButton(
          icon: icon,
          padding: padding,
          constraints: const BoxConstraints(),
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          onPressed: () => _onToggle(context, bookmarkProvider, isBookmarked),
        );
      },
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    BookmarkProvider bookmarkProvider,
    bool wasBookmarked,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await bookmarkProvider.toggleBookmark(
      thread: thread,
      userId: authProvider.uid,
    );

    if (!context.mounted || !showSnackBar) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (wasBookmarked ? 'Removed from saved' : 'Saved for later')
              : 'Failed to update bookmark',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
