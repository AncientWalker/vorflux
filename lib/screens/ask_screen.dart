import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/services/openai_service.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/loading_indicator.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentAnswer;
  String? _currentQuestion;
  String? _errorMessage;

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
      _isLoading = true;
      _errorMessage = null;
      _currentQuestion = question;
      _currentAnswer = null;
    });

    _questionController.clear();
    FocusScope.of(context).unfocus();

    try {
      final answer = await OpenAIService.askQuestion(question);
      setState(() {
        _currentAnswer = answer;
        _isLoading = false;
      });

      // Save to Firestore with user info
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        await context.read<HistoryProvider>().addEntry(
              question: question,
              answer: answer,
              userId: authProvider.uid,
              userName: authProvider.displayName,
              userPhotoURL: authProvider.photoURL,
            );
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentQuestion == null && !_isLoading) _buildWelcomeBanner(),
                  if (_currentQuestion != null) ...[_buildQuestionCard(), const SizedBox(height: 16)],
                  if (_isLoading) ...[const SizedBox(height: 24), const IslamicLoadingIndicator(), const SizedBox(height: 24)],
                  if (_errorMessage != null) _buildErrorCard(),
                  if (_currentAnswer != null) _buildAnswerCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
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

  Widget _buildQuestionCard() {
    return Container(
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
          Text('Your Question', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_currentQuestion!, style: Theme.of(context).textTheme.bodyLarge),
        ])),
      ]),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(width: 12),
        Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error))),
        IconButton(icon: Icon(Icons.refresh, color: AppColors.error), onPressed: () { _questionController.text = _currentQuestion ?? ''; _askQuestion(); }),
      ]),
    );
  }

  Widget _buildAnswerCard() {
    return Container(
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
          Text('Answer from Quran & Hadith', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
        MarkdownBody(
          data: _currentAnswer!,
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
      ]),
    );
  }

  Widget _buildInputArea() {
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
          enabled: !_isLoading,
        )),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _isLoading ? [Colors.grey, Colors.grey] : [AppColors.primary, AppColors.primaryLight]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(color: Colors.transparent, child: InkWell(
            borderRadius: BorderRadius.circular(16), onTap: _isLoading ? null : _askQuestion,
            child: Container(padding: const EdgeInsets.all(14),
              child: Icon(_isLoading ? Icons.hourglass_top : Icons.send_rounded, color: Colors.white, size: 24)),
          )),
        ),
      ]),
    );
  }
}
