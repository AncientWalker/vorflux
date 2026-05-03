import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/detail_screen.dart';
import 'package:vorflux/theme/app_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.isLoading) return const Center(child: CircularProgressIndicator());
        if (feedProvider.hasError) return _buildErrorState(context, feedProvider);
        if (feedProvider.isEmpty) return _buildEmptyState(context);

        final filtered = feedProvider.filteredEntries;

        return Column(children: [
          _buildHeader(context, feedProvider),
          _buildSearchBar(context, feedProvider),
          if (feedProvider.searchQuery.isNotEmpty && filtered.isEmpty)
            _buildNoResultsState(context)
          else
            Expanded(child: RefreshIndicator(
              color: AppColors.primary, onRefresh: feedProvider.refreshFeed,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildFeedCard(context, filtered[index]),
              ),
            )),
        ]);
      },
    );
  }

  Widget _buildHeader(BuildContext context, FeedProvider feedProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Text('Community Feed', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('${feedProvider.entries.length}',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildSearchBar(BuildContext context, FeedProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: provider.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search the community feed...',
          prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
          suffixIcon: provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textHint, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Expanded(
      child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text('No results found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Try a different keyword', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      ]))),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.people_outline, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      const SizedBox(height: 24),
      Text('No Questions Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text('Be the first to ask a question!\nGo to the Ask tab to get started.',
          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
    ])));
  }

  Widget _buildErrorState(BuildContext context, FeedProvider provider) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
      const SizedBox(height: 16),
      Text('Failed to load feed', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: provider.refreshFeed, child: const Text('Retry')),
    ]));
  }

  Widget _buildFeedCard(BuildContext context, QAEntry entry) {
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(entry: entry, isFeedItem: true))),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _buildUserAvatar(entry),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.askedBy ?? 'Anonymous', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
            Text(entry.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right, color: AppColors.textHint),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.help_outline, size: 18, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(child: Text(entry.question, style: Theme.of(context).textTheme.titleMedium)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(entry.answerPreview, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: Text('Read full answer \u2192',
            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
      ])),
    ));
  }

  Widget _buildUserAvatar(QAEntry entry) {
    if (entry.userPhotoURL != null && entry.userPhotoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(entry.userPhotoURL!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        entry.askedBy?.isNotEmpty == true ? entry.askedBy![0].toUpperCase() : '?',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
