import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String messageId, String? feedback)? onFeedback;
  const ChatMessageBubble({super.key, required this.message, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    return message.role == 'user' ? _buildUserBubble(context) : _buildAssistantBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message.content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(message.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.auto_awesome, color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Text('Answer from Quran & Hadith', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.goldDark, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            strong: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            h1: Theme.of(context).textTheme.headlineMedium,
            h2: Theme.of(context).textTheme.headlineSmall,
            listBullet: Theme.of(context).textTheme.bodyLarge,
            blockquoteDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
            ),
            blockquotePadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(message.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        if (onFeedback != null) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Was this helpful?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  message.feedback == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: message.feedback == 'up' ? AppColors.primary : AppColors.textHint,
                ),
                onPressed: () => onFeedback!(
                  message.id,
                  message.feedback == 'up' ? null : 'up',
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Helpful',
              ),
              IconButton(
                icon: Icon(
                  message.feedback == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 18,
                  color: message.feedback == 'down' ? AppColors.error : AppColors.textHint,
                ),
                onPressed: () => onFeedback!(
                  message.id,
                  message.feedback == 'down' ? null : 'down',
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Not helpful',
              ),
            ],
          ),
        ],
      ]),
    );
  }
}
