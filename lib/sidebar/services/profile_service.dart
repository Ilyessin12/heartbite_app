import '../models/user_model.dart';
import '../models/user_stats_model.dart';
import '../models/recipe_model.dart';
import 'supabase_service.dart';

class ProfileService {
  static final _client = SupabaseService.client;

  // Get user profile by ID
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();

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
  } // Get user recipes with sorting

  static Future<List<RecipeModel>> getUserRecipes(
    String userId, {
    String sortBy =
        'created_at', // 'created_at', 'rating', 'cooking_time_minutes'
    bool ascending = false,
  }) async {
    try {
      final response = await _client
          .from('recipes')
          .select('''
            *,
            users(id, username, profile_picture),
            recipe_categories(category_id, categories(name)),
            recipe_gallery_images(id, image_url, caption, order_index),
            recipe_allergens(allergen_id, allergens(id, name, description)),
            recipe_diet_programs(diet_program_id, diet_programs(id, name, description)),
            recipe_equipment(equipment_id, equipment(id, name, description)),
            recipe_likes(count),
            recipe_comments(count)
          ''')
          .eq('user_id', userId)
          .eq('is_published', true)
          .order(sortBy, ascending: ascending);

      // Process and structure the data similar to homepage
      for (final recipe in response) {
        // Calculate like count from joined data or fallback to manual count
        if (recipe['recipe_likes'] != null &&
            (recipe['recipe_likes'] as List).isNotEmpty) {
          recipe['like_count'] = (recipe['recipe_likes'] as List).length;
        } else {
          final likeCountResponse = await _client
              .from('recipe_likes')
              .select('id')
              .eq('recipe_id', recipe['id']);
          recipe['like_count'] = likeCountResponse.length;
        }

        // Calculate comment count from joined data or fallback to manual count
        if (recipe['recipe_comments'] != null &&
            (recipe['recipe_comments'] as List).isNotEmpty) {
          recipe['comment_count'] = (recipe['recipe_comments'] as List).length;
        } else {
          final commentCountResponse = await _client
              .from('recipe_comments')
              .select('id')
              .eq('recipe_id', recipe['id']);
          recipe['comment_count'] = commentCountResponse.length;
        }

        // Process tag data similar to homepage
        recipe['allergens'] =
            (recipe['recipe_allergens'] as List<dynamic>?)
                ?.map((joinRecord) => joinRecord['allergens'])
                .where((tag) => tag != null)
                .toList() ??
            [];

        recipe['diet_programs'] =
            (recipe['recipe_diet_programs'] as List<dynamic>?)
                ?.map((joinRecord) => joinRecord['diet_programs'])
                .where((tag) => tag != null)
                .toList() ??
            [];

        recipe['equipment'] =
            (recipe['recipe_equipment'] as List<dynamic>?)
                ?.map((joinRecord) => joinRecord['equipment'])
                .where((tag) => tag != null)
                .toList() ??
            [];

        // Clean up the join table data
        recipe.remove('recipe_allergens');
        recipe.remove('recipe_diet_programs');
        recipe.remove('recipe_equipment');
        recipe.remove('recipe_likes');
        recipe.remove('recipe_comments');
      }

      return response
          .map<RecipeModel>((json) => RecipeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user recipes: $e');
      return [];
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('users')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Check if username is available
  static Future<bool> isUsernameAvailable(
    String username,
    String currentUserId,
  ) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('username', username)
          .neq('id', currentUserId);

      return response.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Update profile images
  static Future<bool> updateProfileImages({
    required String userId,
    String? profilePictureUrl,
    String? coverPictureUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (profilePictureUrl != null) {
        updates['profile_picture'] = profilePictureUrl;
      }

      if (coverPictureUrl != null) {
        updates['cover_picture'] = coverPictureUrl;
      }

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await _client.from('users').update(updates).eq('id', userId);
      }

      return true;
    } catch (e) {
      print('Error updating profile images: $e');
      return false;
    }
  }
}
