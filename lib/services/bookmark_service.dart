import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';

class BookmarkService {
  final _supabase = SupabaseClientWrapper().client;
  
  /// Get user's bookmark folders
  Future<List<Map<String, dynamic>>> getBookmarkFolders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _supabase
      .from('bookmark_folders')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  }
  
  /// Create a new bookmark folder
  Future<Map<String, dynamic>> createBookmarkFolder({
    required String name,
    String? description,
    bool isDefault = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final result = await _supabase
      .from('bookmark_folders')
      .insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'is_default': isDefault,
      })
      .select()
      .single();
      
    return result;
  }
  
  /// Update bookmark folder
  Future<void> updateBookmarkFolder({
    required int folderId,
    String? name,
    String? description,
    bool? isDefault,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isDefault != null) updates['is_default'] = isDefault;
    
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    await _supabase
      .from('bookmark_folders')
      .update(updates)
      .match({'id': folderId, 'user_id': userId});
  }
  
  /// Delete bookmark folder
  Future<void> deleteBookmarkFolder(int folderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
      .from('bookmark_folders')
      .delete()
      .match({'id': folderId, 'user_id': userId});
  }
  
  /// Get bookmarks from a folder
  Future<List<Map<String, dynamic>>> getBookmarksFromFolder(int folderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _supabase
      .from('recipe_bookmarks')
      .select('''
        *,
        recipes(
          id, title, description, image_url, cooking_time_minutes, 
          difficulty_level, rating, users(id, username, profile_picture)
        )
      ''')
      .match({'folder_id': folderId, 'user_id': userId})
      .order('created_at', ascending: false);
  }
  
  /// Add bookmark to folder
  Future<void> addBookmarkToFolder({
    required int recipeId,
    required int folderId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
      .from('recipe_bookmarks')
      .insert({
        'recipe_id': recipeId,
        'user_id': userId,
        'folder_id': folderId,
      });
  }
  
  /// Remove bookmark from folder
  Future<void> removeBookmarkFromFolder({
    required int recipeId,
    required int folderId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
      .from('recipe_bookmarks')
      .delete()
      .match({
        'recipe_id': recipeId,
        'user_id': userId,
        'folder_id': folderId,
      });
  }
  
  /// Check if recipe is bookmarked by current user
  Future<bool> isRecipeBookmarked(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    
    final result = await _supabase
      .from('recipe_bookmarks')
      .select('id')
      .match({
        'recipe_id': recipeId,
        'user_id': userId,
      });
      
    return result.isNotEmpty;
  }
  
  /// Get folders where a recipe is bookmarked
  Future<List<Map<String, dynamic>>> getRecipeBookmarkFolders(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _supabase
      .from('recipe_bookmarks')
      .select('''
        folder_id,
        bookmark_folders(id, name)
      ''')
      .match({
        'recipe_id': recipeId,
        'user_id': userId,
      });
  }
}
