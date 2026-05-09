import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/chat_message_bubble.dart';
import 'package:vorflux/widgets/user_avatar.dart';

class DetailScreen extends StatefulWidget {
  final ConversationThread thread;
  final bool isFeedItem;

  const DetailScreen({super.key, required this.thread, this.isFeedItem = false});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(widget.thread.messages);
  }

  void _handleFeedback(String messageId, String? feedback) {
    final previousMessages = List<ChatMessage>.from(_messages);

    // Optimistic local update
    setState(() {
      _messages = _messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(feedback: () => feedback);
        }
        return msg;
      }).toList();
    });

    // Persist via provider
    context.read<HistoryProvider>().updateMessageFeedback(
      messageId: messageId,
      threadId: widget.thread.id,
      feedback: feedback,
    ).catchError((e) {
      if (mounted) {
        setState(() { _messages = previousMessages; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save feedback'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy), tooltip: 'Copy conversation',
            onPressed: () {
              final buffer = StringBuffer();
              for (final msg in _messages) {
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
          if (widget.isFeedItem && widget.thread.userName?.isNotEmpty == true) ...[
            Row(children: [
              UserAvatar(photoURL: widget.thread.userPhotoURL, userName: widget.thread.userName, radius: 16),
              const SizedBox(width: 8),
              Text('Asked by ${widget.thread.userName}', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(widget.thread.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
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
            child: Text(widget.thread.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          // All messages with feedback controls for own threads
          ..._messages.map((msg) => ChatMessageBubble(
            message: msg,
            onFeedback: (!widget.isFeedItem && msg.role == 'assistant')
                ? _handleFeedback
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
}
