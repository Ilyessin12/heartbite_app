import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserListItem extends StatelessWidget {
  final String name;
  final String username;
  final String avatarUrl;
  final bool isFollowing;
  final VoidCallback onFollowTap;

  const UserListItem({
    super.key,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.isFollowing = false,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.grayLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.grayDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onFollowTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Unfollow',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
