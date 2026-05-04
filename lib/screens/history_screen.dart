import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/history_provider.dart';
import 'package:vorflux/screens/detail_screen.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/search_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Keeps the [TextEditingController] in sync when the provider's
  /// search query is cleared externally (e.g. via [stopListening]).
  void _syncController(String providerQuery) {
    if (_searchController.text != providerQuery) {
      _searchController.text = providerQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        _syncController(historyProvider.searchQuery);

        if (historyProvider.isLoading) return const Center(child: CircularProgressIndicator());
        if (historyProvider.isEmpty) return _buildEmptyState(context);

        final filtered = historyProvider.filteredEntries;

        return Column(children: [
          _buildHeader(context, historyProvider),
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search your questions...',
            searchQuery: historyProvider.searchQuery,
            onChanged: historyProvider.setSearchQuery,
            onClear: () => historyProvider.setSearchQuery(''),
          ),
          if (historyProvider.searchQuery.isNotEmpty && filtered.isEmpty)
            const NoResultsState()
          else
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildHistoryCard(context, filtered[index], historyProvider),
            )),
        ]);
      },
    );
  }

  Widget _buildHeader(BuildContext context, HistoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Questions', style: Theme.of(context).textTheme.headlineSmall),
          Text('${provider.entries.length} saved', style: Theme.of(context).textTheme.bodySmall),
        ]),
        if (provider.entries.isNotEmpty)
          TextButton.icon(
            icon: Icon(Icons.delete_sweep, color: AppColors.error, size: 18),
            label: Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 13)),
            onPressed: () => _showClearDialog(context, provider),
          ),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.history_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      const SizedBox(height: 24),
      Text('No History Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text('Your questions and answers will appear here.\nGo to the Ask tab to get started!',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
    ])));
  }

  Widget _buildHistoryCard(BuildContext context, QAEntry entry, HistoryProvider provider) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Entry deleted'), behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      },
      child: Card(child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(entry: entry))),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.question_answer, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.question, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(entry.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
            ])),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Text(entry.answerPreview, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ])),
      )),
    );
  }

  void _showClearDialog(BuildContext context, HistoryProvider provider) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Clear All History?'),
      content: const Text('This will permanently delete all your saved questions and answers. This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            provider.clearHistory();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('History cleared'), behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            );
          },
          child: Text('Clear All', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}
