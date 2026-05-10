import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/theme/app_theme.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Future<void> Function(String messageId, String? feedback)? onFeedback;
  final bool isStreaming;
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onFeedback,
    this.isStreaming = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  AnimationController? _cursorController;

  @override
  void initState() {
    super.initState();
    if (widget.isStreaming) {
      _startCursorAnimation();
    }
  }

  @override
  void didUpdateWidget(ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && _cursorController == null) {
      _startCursorAnimation();
    } else if (!widget.isStreaming && _cursorController != null) {
      _cursorController!.stop();
      _cursorController!.dispose();
      _cursorController = null;
    }
  }

  void _startCursorAnimation() {
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController?.dispose();
    super.dispose();
  }

  Future<void> _onFeedbackTap(String messageId, String? feedback) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onFeedback!(messageId, feedback);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.message.role == 'user' ? _buildUserBubble(context) : _buildAssistantBubble(context);
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
          Text(widget.message.content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(widget.message.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
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
        if (widget.message.content.isNotEmpty)
          MarkdownBody(
            data: widget.message.content,
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
        if (widget.isStreaming && _cursorController != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FadeTransition(
              opacity: _cursorController!,
              child: Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        if (!widget.isStreaming) ...[
          const SizedBox(height: 4),
          Text(widget.message.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
        if (widget.onFeedback != null) ...[
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
                  widget.message.feedback == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: widget.message.feedback == 'up' ? AppColors.primary : AppColors.textHint,
                ),
                onPressed: _isSaving
                    ? null
                    : () => _onFeedbackTap(
                          widget.message.id,
                          widget.message.feedback == 'up' ? null : 'up',
                        ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Helpful',
              ),
              IconButton(
                icon: Icon(
                  widget.message.feedback == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 18,
                  color: widget.message.feedback == 'down' ? AppColors.error : AppColors.textHint,
                ),
                onPressed: _isSaving
                    ? null
                    : () => _onFeedbackTap(
                          widget.message.id,
                          widget.message.feedback == 'down' ? null : 'down',
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
