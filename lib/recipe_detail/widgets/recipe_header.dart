import 'package:flutter/material.dart';
import '../../services/supabase_client.dart'; // For current user
import '../../sidebar/services/follow_service.dart';
import '../models/recipe.dart';
import '../utils/constants.dart';

class RecipeHeader extends StatefulWidget {
  final Recipe recipe;
  final bool showAuthor;
  final bool showOverlayInfo;
  final int likeCount;
  final bool isFavorite;
  final String authorId; // Add authorId

  const RecipeHeader({
    super.key,
    required this.recipe,
    this.showAuthor = true,
    this.showOverlayInfo = true,
    required this.likeCount,
    required this.isFavorite,
    required this.authorId, // Add authorId
  });

  @override
  State<RecipeHeader> createState() => _RecipeHeaderState();
}

class _RecipeHeaderState extends State<RecipeHeader> {
  int _followersCount = 0;
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;
  String? _authorProfilePicture;

  @override
  void initState() {
    super.initState();
    _fetchFollowData();
    _fetchAuthorProfilePicture();
  }

  Future<void> _fetchFollowData() async {
    if (widget.authorId.isEmpty) {
      setState(() {
        _isLoadingFollowStatus = false;
      });
      return;
    }
    try {
      final followers = await FollowService.getFollowers(widget.authorId);
      final isFollowing = await FollowService.isFollowing(widget.authorId);
      if (mounted) {
        setState(() {
          _followersCount = followers.length;
          _isFollowing = isFollowing;
          _isLoadingFollowStatus = false;
        });
      }
    } catch (e) {
      print('Error fetching follow data: $e');
      if (mounted) {
        setState(() {
          _isLoadingFollowStatus = false;
        });
      }
    }
  }

  Future<void> _fetchAuthorProfilePicture() async {
    if (widget.authorId.isEmpty) return;
    try {
      final userData = await SupabaseClientWrapper()
          .client
          .from('users')
          .select('profile_picture')
          .eq('id', widget.authorId)
          .single();
      if (mounted && userData['profile_picture'] != null) {
        setState(() {
          _authorProfilePicture = userData['profile_picture'] as String;
        });
      }
    } catch (e) {
      print('Error fetching author profile picture: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = SupabaseClientWrapper().client.auth.currentUser?.id;
    if (currentUserId == null || widget.authorId == currentUserId) return;

    setState(() {
      _isLoadingFollowStatus = true;
    });

    try {
      bool success;
      if (_isFollowing) {
        success = await FollowService.unfollowUser(widget.authorId);
      } else {
        success = await FollowService.followUser(widget.authorId);
      }

      if (success) {
        _fetchFollowData(); // Refresh data
      } else {
        // Handle error, maybe show a snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFollowing
                    ? 'Failed to unfollow user'
                    : 'Failed to follow user',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingFollowStatus = false;
          });
        }
      }
    } catch (e) {
      print('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingFollowStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseClientWrapper().client.auth.currentUser?.id;
    final isAuthorViewingOwnRecipe = widget.authorId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showAuthor) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Author info on the left
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: _authorProfilePicture != null &&
                            _authorProfilePicture!.isNotEmpty
                        ? NetworkImage(_authorProfilePicture!)
                        : const AssetImage(
                            "assets/images/avatars/avatar1.jpg",
                          ) as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$_followersCount Followers",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),

              // Follow/Unfollow button or empty space
              if (!isAuthorViewingOwnRecipe && !_isLoadingFollowStatus)
                ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(
                    _isFollowing ? 'Unfollow' : 'Follow',
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else if (_isLoadingFollowStatus && !isAuthorViewingOwnRecipe)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else // Placeholder for author or when button is hidden
                const SizedBox(width: 70), // Adjust width as needed
            ],
          ),
          const SizedBox(height: 12),
        ],
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.recipe.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.recipe.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(
                        'assets/images/cookbooks/placeholder_image.jpg', // Placeholder image
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/cookbooks/placeholder_image.jpg', // Placeholder for empty URL
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            if (widget.showOverlayInfo) ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: widget.isFavorite ? Colors.red : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.likeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recipe.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}