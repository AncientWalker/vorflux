import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/chat_message_bubble.dart';
import 'package:vorflux/widgets/user_avatar.dart';

class DetailScreen extends StatelessWidget {
  final ConversationThread thread;
  final bool isFeedItem;

  const DetailScreen({super.key, required this.thread, this.isFeedItem = false});

  /// Returns the live messages list. For own-thread views the provider's
  /// `activeThread` is the source of truth so optimistic feedback updates
  /// are reflected immediately. For feed-item views (other users' threads)
  /// we fall back to the snapshot passed in at construction time.
  List<ChatMessage> _resolveMessages(HistoryProvider provider) {
    if (!isFeedItem) {
      final active = provider.activeThread;
      if (active != null && active.id == thread.id) {
        return active.messages;
      }
    }
    return thread.messages;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();
    final messages = _resolveMessages(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy), tooltip: 'Copy conversation',
            onPressed: () {
              final buffer = StringBuffer();
              for (final msg in messages) {
                buffer.writeln(msg.role == 'user' ? 'Q: ${msg.content}' : 'A: ${msg.content}');
                buffer.writeln();
              }
              Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Copied to clipboard'), behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (isFeedItem && thread.userName?.isNotEmpty == true) ...[
            Row(children: [
              UserAvatar(photoURL: thread.userPhotoURL, userName: thread.userName, radius: 16),
              const SizedBox(width: 8),
              Text('Asked by ${thread.userName}', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(thread.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 16),
          ],
          // Thread title header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(thread.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          // All messages with feedback controls for own threads
          ...messages.map((msg) => ChatMessageBubble(
            message: msg,
            onFeedback: (!isFeedItem && msg.role == 'assistant')
                ? (messageId, feedback) => _handleFeedback(context, messageId, feedback)
                : null,
          )),
          // Disclaimer
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppColors.textHint, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Always verify citations with scholarly sources. AI responses may contain inaccuracies.',
                  style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Future<void> _handleFeedback(BuildContext context, String messageId, String? feedback) async {
    try {
      await context.read<HistoryProvider>().updateMessageFeedback(
        messageId: messageId,
        threadId: thread.id,
        feedback: feedback,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save feedback'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
