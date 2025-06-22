import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';

class BookmarkService {
  final _supabase = SupabaseClientWrapper().client;

  /// Ensure "Saved" folder exists for current user and return its ID
  Future<int> ensureSavedFolderExists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if "Saved" folder exists
    final existingSaved =
        await _supabase
            .from('bookmark_folders')
            .select('id')
            .eq('user_id', userId)
            .eq('is_default', true)
            .maybeSingle();

    if (existingSaved != null) {
      return existingSaved['id'] as int;
    }

    // Create "Saved" folder with first recipe's image as cover
    final result =
        await _supabase
            .from('bookmark_folders')
            .insert({
              'user_id': userId,
              'name': 'Saved',
              'is_default': true,
              'description': 'All your saved recipes',
            })
            .select()
            .single();

    return result['id'] as int;
  }

  /// Get saved recipes (from default "Saved" folder)
  Future<List<Map<String, dynamic>>> getSavedRecipes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final savedFolderId = await ensureSavedFolderExists();

    return await _supabase
        .from('recipe_bookmarks')
        .select('''
        *,
        recipes(
          id, title, description, image_url, cooking_time_minutes, 
          difficulty_level, rating, users(id, username, profile_picture)
        )
      ''')
        .eq('user_id', userId)
        .eq('folder_id', savedFolderId)
        .order('created_at', ascending: false);
  }

  /// Check if user has custom bookmark folders (excluding default "Saved")
  Future<bool> hasCustomBookmarkFolders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final customFolders = await _supabase
        .from('bookmark_folders')
        .select('id')
        .eq('user_id', userId)
        .eq('is_default', false);

    return customFolders.isNotEmpty;
  }

  /// Update folder cover image with first recipe's image
  Future<void> updateFolderCoverImage(int folderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get first recipe from folder
    final firstRecipe =
        await _supabase
            .from('recipe_bookmarks')
            .select('''
        recipes(image_url)
      ''')
            .eq('folder_id', folderId)
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (firstRecipe != null && firstRecipe['recipes'] != null) {
      final imageUrl = firstRecipe['recipes']['image_url'];
      if (imageUrl != null) {
        await _supabase
            .from('bookmark_folders')
            .update({'image_url': imageUrl})
            .eq('id', folderId)
            .eq('user_id', userId);
      }
    }
  }

  /// Get user's bookmark folders with recipe counts
  Future<List<Map<String, dynamic>>> getBookmarkFolders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Ensure "Saved" folder exists
    await ensureSavedFolderExists();

    // Get folders with recipe counts in a single query
    final folders = await _supabase
        .from('bookmark_folders')
        .select('''
          *,
          recipe_bookmarks(count)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Process the results to extract recipe counts
    final processedFolders =
        folders.map((folder) {
          final recipeBookmarks = folder['recipe_bookmarks'] as List?;
          final recipeCount = recipeBookmarks?.length ?? 0;

          // Remove the nested recipe_bookmarks and add recipe_count
          final processedFolder = Map<String, dynamic>.from(folder);
          processedFolder.remove('recipe_bookmarks');
          processedFolder['recipe_count'] = recipeCount;

          return processedFolder;
        }).toList();

    // Sort folders: "Saved" first, then others
    processedFolders.sort((a, b) {
      if (a['is_default'] == true) return -1;
      if (b['is_default'] == true) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });

    return processedFolders;
  }

  /// Create a new bookmark folder
  Future<Map<String, dynamic>> createBookmarkFolder({
    required String name,
    String? imageUrl,
    String? description,
    bool isDefault = false,
    List<int>? recipeIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result =
        await _supabase
            .from('bookmark_folders')
            .insert({
              'user_id': userId,
              'name': name,
              'image_url': imageUrl,
              'description': description,
              'is_default': isDefault,
            })
            .select()
            .single();

    if (recipeIds != null && recipeIds.isNotEmpty) {
      final folderId = result['id'];
      final bookmarks =
          recipeIds
              .map(
                (recipeId) => {
                  'recipe_id': recipeId,
                  'user_id': userId,
                  'folder_id': folderId,
                },
              )
              .toList();

      await _supabase.from('recipe_bookmarks').insert(bookmarks);
    }

    return result;
  }

  /// Update bookmark folder
  Future<void> updateBookmarkFolder({
    required int folderId,
    String? name,
    String? imageUrl,
    String? description,
    bool? isDefault,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (description != null) updates['description'] = description;
    if (isDefault != null) updates['is_default'] = isDefault;

    updates['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('bookmark_folders').update(updates).match({
      'id': folderId,
      'user_id': userId,
    });
  }

  /// Delete bookmark folder (prevent deletion of "Saved" folder)
  Future<void> deleteBookmarkFolders(List<int> folderIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Filter out the "Saved" folder to prevent deletion
    final savedFolderId = await ensureSavedFolderExists();
    final filteredIds = folderIds.where((id) => id != savedFolderId).toList();

    if (filteredIds.isNotEmpty) {
      await _supabase
          .from('bookmark_folders')
          .delete()
          .inFilter('id', filteredIds)
          .match({'user_id': userId});
    }
  }

  /// Get bookmarks from a folder
  Future<List<Map<String, dynamic>>> getBookmarksFromFolder(
    int folderId,
  ) async {
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

  /// Add bookmark to folder (Instagram-like behavior)
  Future<void> addBookmarkToFolder({
    required int recipeId,
    required int folderId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Ensure "Saved" folder exists
    final savedFolderId = await ensureSavedFolderExists();

    // First, add to "Saved" if not already there
    final existingInSaved =
        await _supabase
            .from('recipe_bookmarks')
            .select('id')
            .eq('recipe_id', recipeId)
            .eq('user_id', userId)
            .eq('folder_id', savedFolderId)
            .maybeSingle();

    if (existingInSaved == null) {
      await _supabase.from('recipe_bookmarks').insert({
        'recipe_id': recipeId,
        'user_id': userId,
        'folder_id': savedFolderId,
      });

      // Update "Saved" folder cover if it's the first recipe
      await updateFolderCoverImage(savedFolderId);
    }

    // Then add to the specified folder (if it's not "Saved")
    if (folderId != savedFolderId) {
      final existingInFolder =
          await _supabase
              .from('recipe_bookmarks')
              .select('id')
              .eq('recipe_id', recipeId)
              .eq('user_id', userId)
              .eq('folder_id', folderId)
              .maybeSingle();

      if (existingInFolder == null) {
        await _supabase.from('recipe_bookmarks').insert({
          'recipe_id': recipeId,
          'user_id': userId,
          'folder_id': folderId,
        });

        // Update folder cover
        await updateFolderCoverImage(folderId);
      }
    }
  }

  /// Remove bookmark from folder (Instagram-like behavior)
  Future<void> removeBookmarkFromFolder({
    required int recipeId,
    required int folderId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final savedFolderId = await ensureSavedFolderExists();

    if (folderId == savedFolderId) {
      // Removing from "Saved" = remove from ALL folders
      await _supabase.from('recipe_bookmarks').delete().match({
        'recipe_id': recipeId,
        'user_id': userId,
      });

      // Update all folder covers that might have been affected
      final allFolders = await _supabase
          .from('bookmark_folders')
          .select('id')
          .eq('user_id', userId);

      for (final folder in allFolders) {
        await updateFolderCoverImage(folder['id']);
      }
    } else {
      // Removing from custom folder = only remove from that folder
      await _supabase.from('recipe_bookmarks').delete().match({
        'recipe_id': recipeId,
        'user_id': userId,
        'folder_id': folderId,
      });

      // Update folder cover
      await updateFolderCoverImage(folderId);
    }
  }

  /// Remove multiple bookmarks from folder (bulk operation)
  Future<void> removeMultipleBookmarksFromFolder({
    required List<int> recipeIds,
    required int folderId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final savedFolderId = await ensureSavedFolderExists();

    if (folderId == savedFolderId) {
      // Removing from "Saved" = remove from ALL folders
      await _supabase
          .from('recipe_bookmarks')
          .delete()
          .inFilter('recipe_id', recipeIds)
          .eq('user_id', userId);

      // Update all folder covers that might have been affected
      final allFolders = await _supabase
          .from('bookmark_folders')
          .select('id')
          .eq('user_id', userId);

      for (final folder in allFolders) {
        await updateFolderCoverImage(folder['id']);
      }
    } else {
      // Removing from custom folder = only remove from that folder
      await _supabase
          .from('recipe_bookmarks')
          .delete()
          .inFilter('recipe_id', recipeIds)
          .eq('user_id', userId)
          .eq('folder_id', folderId);

      // Update folder cover
      await updateFolderCoverImage(folderId);
    }
  }

  /// Check if recipe is bookmarked by current user (check in "Saved" folder)
  Future<bool> isRecipeBookmarked(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final savedFolderId = await ensureSavedFolderExists();

    final result = await _supabase.from('recipe_bookmarks').select('id').match({
      'recipe_id': recipeId,
      'user_id': userId,
      'folder_id': savedFolderId,
    });

    return result.isNotEmpty;
  }

  /// Get folders where a recipe is bookmarked
  Future<List<Map<String, dynamic>>> getRecipeBookmarkFolders(
    int recipeId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('recipe_bookmarks')
        .select('''
        folder_id,
        bookmark_folders(id, name)
      ''')
        .match({'recipe_id': recipeId, 'user_id': userId});
  }

  /// Get the count of recipes in a specific folder
  Future<int> getRecipeCountInFolder(int folderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final result = await _supabase.from('recipe_bookmarks').select('id').match({
      'folder_id': folderId,
      'user_id': userId,
    });

    return result.length;
  }
}
