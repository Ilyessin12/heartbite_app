import '../models/user_model.dart';
import '../models/user_stats_model.dart';
import '../models/recipe_model.dart';
import 'supabase_service.dart';

class ProfileService {
  static final _client = SupabaseService.client;

  // Get user profile by ID
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;
    
    return getUserProfile(userId);
  }

  // Get user stats (recipes, followers, following count)
  static Future<UserStatsModel> getUserStats(String userId) async {
    try {
      // Get recipes count
      final recipesResponse = await _client
          .from('recipes')
          .select('id')
          .eq('user_id', userId)
          .eq('is_published', true);
      
      // Get followers count
      final followersResponse = await _client
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);
      
      // Get following count
      final followingResponse = await _client
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId);

      return UserStatsModel(
        recipesCount: recipesResponse.length,
        followersCount: followersResponse.length,
        followingCount: followingResponse.length,
      );
    } catch (e) {
      print('Error getting user stats: $e');
      return UserStatsModel(
        recipesCount: 0,
        followersCount: 0,
        followingCount: 0,
      );
    }
  }

  // Get user recipes with sorting
  static Future<List<RecipeModel>> getUserRecipes(
    String userId, {
    String sortBy = 'created_at', // 'created_at', 'rating', 'cooking_time_minutes'
    bool ascending = false,
  }) async {
    try {
      final response = await _client
          .from('recipes')
          .select()
          .eq('user_id', userId)
          .eq('is_published', true)
          .order(sortBy, ascending: ascending);

      return response.map<RecipeModel>((json) => RecipeModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user recipes: $e');
      return [];
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('users')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
}
