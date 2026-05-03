import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vorflux/theme/app_theme.dart';

class IslamicLoadingIndicator extends StatelessWidget {
  const IslamicLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Searching Quran & Hadith...',
                style: TextStyle(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: AppColors.surfaceVariant,
            highlightColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerLine(1.0),
                const SizedBox(height: 10),
                _buildShimmerLine(0.9),
                const SizedBox(height: 10),
                _buildShimmerLine(0.7),
                const SizedBox(height: 10),
                _buildShimmerLine(0.85),
                const SizedBox(height: 10),
                _buildShimmerLine(0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLine(double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
