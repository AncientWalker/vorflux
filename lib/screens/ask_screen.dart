import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/chat_message_bubble.dart';
import 'package:vorflux/widgets/loading_indicator.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;
  String? _lastFailedQuestion;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _lastFailedQuestion = null;
    });
    _questionController.clear();
    FocusScope.of(context).unfocus();

    try {
      await context.read<HistoryProvider>().sendMessage(question);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _lastFailedQuestion = question;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final activeThread = historyProvider.activeThread;
    final isSending = historyProvider.isSending;
    final isLoading = historyProvider.isLoading;
    final isInputDisabled = isSending || isLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : activeThread == null || activeThread.messages.isEmpty
                    ? SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        child: _buildWelcomeBanner(),
                      )
                    : _buildMessageList(activeThread, isSending),
          ),
          if (_errorMessage != null) _buildErrorBanner(),
          _buildInputArea(isInputDisabled),
        ],
      ),
    );
  }

  Widget _buildMessageList(ConversationThread thread, bool isSending) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: thread.messages.length + (isSending ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index < thread.messages.length) {
          return ChatMessageBubble(message: thread.messages[index]);
        }
        if (isSending && index == thread.messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: IslamicLoadingIndicator(),
          );
        }
        return const SizedBox(height: 80);
      },
    );
  }

  Widget _buildWelcomeBanner() {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.displayName.split(' ').first;
    final greeting = firstName.isNotEmpty && firstName != 'Anonymous'
        ? 'Assalamu Alaikum, $firstName!'
        : 'Assalamu Alaikum!';

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.gold.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.menu_book_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(greeting,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Ask from the Quran & Hadith',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Get answers sourced exclusively from the Holy Quran and authentic Hadith collections with specific citations.',
              style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('What does Islam say about patience?'),
              _buildSuggestionChip('Importance of prayer in the Quran'),
              _buildSuggestionChip('Rights of parents in Islam'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: TextStyle(fontSize: 12, color: AppColors.primary)),
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () { _questionController.text = text; _askQuestion(); },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error, fontSize: 13))),
        if (_lastFailedQuestion != null)
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.error, size: 20),
            onPressed: () {
              _questionController.text = _lastFailedQuestion!;
              _askQuestion();
            },
          ),
      ]),
    );
  }

  Widget _buildInputArea(bool disabled) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _questionController, maxLines: 3, minLines: 1,
          textInputAction: TextInputAction.send, onSubmitted: (_) => _askQuestion(),
          decoration: InputDecoration(
            hintText: 'Ask a question about Islam...',
            prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.mosque_outlined, color: AppColors.primary.withValues(alpha: 0.5))),
          ),
          enabled: !disabled,
        )),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: disabled ? [Colors.grey, Colors.grey] : [AppColors.primary, AppColors.primaryLight]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(color: Colors.transparent, child: InkWell(
            borderRadius: BorderRadius.circular(16), onTap: disabled ? null : _askQuestion,
            child: Container(padding: const EdgeInsets.all(14),
              child: Icon(disabled ? Icons.hourglass_top : Icons.send_rounded, color: Colors.white, size: 24)),
          )),
        ),
      ]),
    );
  }
}
