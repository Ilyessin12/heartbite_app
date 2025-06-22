import '../models/follow_user_model.dart';
import 'supabase_service.dart';

class FollowService {
  static final _client = SupabaseService.client;

  // Get followers list
  static Future<List<FollowUserModel>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('user_follows')
          .select('''
            created_at,
            follower_id,
            users!user_follows_follower_id_fkey (
              id,
              full_name,
              username,
              profile_picture
            )
          ''')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      return response.map<FollowUserModel>((item) {
        final user = item['users'];
        return FollowUserModel(
          id: user['id'],
          fullName: user['full_name'],
          username: user['username'],
          profilePicture: user['profile_picture'],
          followedAt: DateTime.parse(item['created_at']),
          isFollowing: true,
        );
      }).toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following list
  static Future<List<FollowUserModel>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('user_follows')
          .select('''
            created_at,
            following_id,
            users!user_follows_following_id_fkey (
              id,
              full_name,
              username,
              profile_picture
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return response.map<FollowUserModel>((item) {
        final user = item['users'];
        return FollowUserModel(
          id: user['id'],
          fullName: user['full_name'],
          username: user['username'],
          profilePicture: user['profile_picture'],
          followedAt: DateTime.parse(item['created_at']),
          isFollowing: true,
        );
      }).toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Follow user
  static Future<bool> followUser(String targetUserId) async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) return false;

      await _client.from('user_follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow user
  static Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) return false;

      await _client
          .from('user_follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following target user
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) return false;

      final response = await _client
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Remove follower (block/remove from followers)
  static Future<bool> removeFollower(String followerId) async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) return false;

      await _client
          .from('user_follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', currentUserId);

      return true;
    } catch (e) {
      print('Error removing follower: $e');
      return false;
    }
  }
}
