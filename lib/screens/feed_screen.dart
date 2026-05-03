import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/models/qa_entry.dart';
import 'package:vorflux/providers/feed_provider.dart';
import 'package:vorflux/screens/detail_screen.dart';
import 'package:vorflux/theme/app_theme.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (feedProvider.hasError) {
          return _buildErrorState(context, feedProvider);
        }

        return Column(
          children: [
            _buildHeader(context),
            _buildCommunityBanner(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: feedProvider.refreshFeed,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: feedProvider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = feedProvider.entries[index];
                    return _buildFeedCard(context, entry);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'SAMPLE',
              style: TextStyle(
                color: AppColors.goldDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.goldDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is sample community data. In a full version, this would show real questions from other users.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.goldDark,
                  ),
            ),
          ),
        ],
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

  Widget _buildFeedCard(BuildContext context, QAEntry entry) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(entry: entry, isFeedItem: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      entry.askedBy?.isNotEmpty == true
                          ? entry.askedBy![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.askedBy ?? 'Anonymous',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                            ),
                      ),
                      Text(
                        entry.formattedTimestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 12),
              // Question
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
                        entry.question,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Answer preview
              Text(
                entry.answerPreview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Read more
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Read full answer →',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
