import 'package:flutter/material.dart';
import 'package:vorflux/theme/app_theme.dart';

/// Shared avatar widget for displaying user photos or initials.
class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final String? userName;
  final double radius;

  const UserAvatar({
    super.key,
    this.photoURL,
    this.userName,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (photoURL != null && photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(photoURL!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
