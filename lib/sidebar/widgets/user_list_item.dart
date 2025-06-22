import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/follow_user_model.dart';

enum UserActionType {
  none,
  follow,
  unfollow,
  remove,
}

class UserListItem extends StatelessWidget {
  final FollowUserModel user;
  final UserActionType actionType;
  final VoidCallback? onActionTap;
  final VoidCallback? onUserTap;

  const UserListItem({
    super.key,
    required this.user,
    this.actionType = UserActionType.none,
    this.onActionTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUserTap,
      child: Container(
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
            // Profile Picture
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Text(
                      user.fullName.isNotEmpty 
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: AppColors.grayDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Button
            if (actionType != UserActionType.none && onActionTap != null)
              _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    String text;
    Color color;
    Color backgroundColor;

    switch (actionType) {
      case UserActionType.follow:
        text = 'Follow';
        color = Colors.white;
        backgroundColor = AppColors.primary;
        break;
      case UserActionType.unfollow:
        text = 'Batal Ikuti';
        color = AppColors.primary;
        backgroundColor = Colors.white;
        break;
      case UserActionType.remove:
        text = 'Hapus';
        color = Colors.red;
        backgroundColor = Colors.white;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: actionType == UserActionType.follow 
                ? AppColors.primary 
                : (actionType == UserActionType.remove ? Colors.red : AppColors.primary),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
