import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/theme/app_theme.dart';

class DetailScreen extends StatelessWidget {
  final QAEntry entry;
  final bool isFeedItem;

  const DetailScreen({super.key, required this.entry, this.isFeedItem = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Answer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy), tooltip: 'Copy answer',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${entry.question}\n\n${entry.answer}'));
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
          if (isFeedItem && entry.askedBy != null) ...[
            Row(children: [
              _buildUserAvatar(),
              const SizedBox(width: 8),
              Text('Asked by ${entry.askedBy}', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(entry.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.help_outline, color: Colors.white.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 8),
                Text('Question', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ]),
              const SizedBox(height: 8),
              Text(entry.question, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
              if (!isFeedItem) ...[
                const SizedBox(height: 8),
                Text(entry.formattedTimestamp, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Answer', style: Theme.of(context).textTheme.titleMedium),
                  Text('From Quran & Hadith sources', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ]),
              const SizedBox(height: 16), const Divider(height: 1), const SizedBox(height: 16),
              MarkdownBody(
                data: entry.answer, selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
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
          ),
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

  Widget _buildUserAvatar() {
    if (entry.userPhotoURL != null && entry.userPhotoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(entry.userPhotoURL!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(entry.askedBy![0].toUpperCase(),
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }
}
