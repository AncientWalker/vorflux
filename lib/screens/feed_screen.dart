import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/detail_screen.dart';
import 'package:vorflux/theme/app_theme.dart';
import 'package:vorflux/widgets/search_bar.dart';
import 'package:vorflux/widgets/user_avatar.dart';

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

  void _syncController(String providerQuery) {
    if (_searchController.text != providerQuery) {
      _searchController.text = providerQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        _syncController(feedProvider.searchQuery);

        if (feedProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (feedProvider.hasError) {
          return _buildErrorState(context, feedProvider);
        }
        if (feedProvider.isEmpty) {
          return _buildEmptyState(context);
        }

        final filtered = feedProvider.filteredEntries;

        return Column(
          children: [
            _buildHeader(context, feedProvider),
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search the community feed...',
              searchQuery: feedProvider.searchQuery,
              onChanged: feedProvider.setSearchQuery,
              onClear: () => feedProvider.setSearchQuery(''),
            ),
            if (feedProvider.searchQuery.isNotEmpty && filtered.isEmpty)
              const NoResultsState()
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: feedProvider.refreshFeed,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildFeedCard(context, filtered[index]);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FeedProvider feedProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Community Feed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${feedProvider.threads.length}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start a conversation!\nGo to the Ask tab to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FeedProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Failed to load feed',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: provider.refreshFeed,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, ConversationThread thread) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final feedProvider = context.read<FeedProvider>();
          final fullThread = await feedProvider.getFullThread(thread.id);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(thread: fullThread, isFeedItem: true),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    photoURL: thread.userPhotoURL,
                    userName: thread.userName,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.userName?.isNotEmpty == true
                            ? thread.userName!
                            : 'Anonymous',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 14),
                      ),
                      Text(
                        thread.formattedTimestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        thread.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (thread.lastMessagePreview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  thread.lastMessagePreview,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${thread.messageCount} messages',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Read full conversation →',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
