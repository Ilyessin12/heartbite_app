import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final _supabase = SupabaseClientWrapper().client;

  /// Get all public recipes with gallery images
  Future<List<Map<String, dynamic>>> getPublicRecipesWithDetails({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
  }) async {
    var queryBuilder = _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name)),
          recipe_gallery_images(id, image_url, caption, order_index)
        ''')
        .eq('is_published', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchPattern = '%${searchQuery.trim().replaceAll(' ', '%')}%';
      queryBuilder = queryBuilder.or('title.ilike.$searchPattern,description.ilike.$searchPattern');
    }

    final finalQuery = queryBuilder
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    final response = await finalQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get recipe details by ID including gallery images, ingredients, and instructions
  Future<Map<String, dynamic>> getRecipeDetailsById(int recipeId, {String? currentUserId}) async {
    // Fetch main recipe data and basic comment structure
    final Map<String, dynamic> recipeDataMap = await _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name)),
          recipe_gallery_images(id, image_url, caption, order_index),
          recipe_ingredients(id, recipe_id, ingredients, quantity, unit, notes, order_index),
          recipe_instructions(id, recipe_id, step_number, instruction, image_url, estimated_time_minutes),
          recipe_comments(
            id,
            comment,
            created_at,
            parent_comment_id,
            user_id,
            users (id, username, profile_picture),
            comment_likes (count)
          )
        ''')
        .eq('id', recipeId)
        .order('created_at', referencedTable: 'recipe_comments', ascending: true)
        .single(); // .single() returns a Future<Map<String, dynamic>> effectively after await
    
    // recipeDataMap is now correctly typed and contains the fetched data.

    // Now, if currentUserId is provided, fetch the IDs of comments liked by this user for this recipe
    if (currentUserId != null && recipeDataMap['recipe_comments'] != null) {
      final List<dynamic> comments = recipeDataMap['recipe_comments'];
      if (comments.isNotEmpty) {
        final List<int> commentIds = comments.map((c) => c['id'] as int).toList();
        
        // Explicitly define the builder before using .in_()
        final PostgrestFilterBuilder<List<Map<String, dynamic>>> likedCommentsQueryBuilder = _supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', currentUserId);

        // Now call .filter() on the explicitly typed builder
        // Format commentIds into a string like '(id1,id2,id3)'
        List<Map<String, dynamic>> likedCommentData; // Declare here
        if (commentIds.isEmpty) { // Handle empty list to avoid invalid filter like "in ()"
          likedCommentData = [];
        } else {
          final String commentIdsString = '(${commentIds.join(',')})';
          likedCommentData = await likedCommentsQueryBuilder
              .filter('comment_id', 'in', commentIdsString);
        }

        final Set<int> likedCommentIds = likedCommentData
            .map((likeMap) => likeMap['comment_id'] as int)
            .toSet();

        // Augment comment data with is_liked status
        // Ensure we are modifying the list that is part of recipeDataMap
        for (var comment in recipeDataMap['recipe_comments']) { 
          comment['is_liked_by_current_user'] = likedCommentIds.contains(comment['id']);
        }
      }
    }
    return recipeDataMap; // Return the modified recipeDataMap
  }

  // _getOrCreateIngredientId is no longer needed as ingredient name is stored directly.

  Future<RecipeModel> createRecipe(RecipeModel recipeModel, List<String> galleryImageUrls) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please log in to create a recipe.');
    }
    // Update the recipeModel with the correct user_id before converting to JSON
    recipeModel.user_id = userId;

    final Map<String, dynamic> recipeData = recipeModel.toJson();
    recipeData.remove('id');
    recipeData.remove('created_at');
    recipeData.remove('updated_at');
    recipeData.remove('gallery_image_urls');
    recipeData.remove('ingredients');
    recipeData.remove('instructions');
    recipeData.remove('ingredients_text');
    recipeData.remove('directions_text');

    final insertedRecipeData = await _supabase
        .from('recipes')
        .insert(recipeData)
        .select()
        .single();

    final newRecipeId = insertedRecipeData['id'] as int;

    if (galleryImageUrls.isNotEmpty) {
      final List<Map<String, dynamic>> galleryImagesData = galleryImageUrls
          .asMap()
          .entries
          .map((entry) => {
                'recipe_id': newRecipeId,
                'image_url': entry.value,
                'order_index': entry.key,
              })
          .toList();
      await _supabase.from('recipe_gallery_images').insert(galleryImagesData);
    }
    insertedRecipeData['gallery_image_urls'] = galleryImageUrls;

    if (recipeModel.ingredients != null && recipeModel.ingredients!.isNotEmpty) {
      final List<Map<String, dynamic>> recipeIngredientsData = recipeModel.ingredients!
          .map((ingModel) {
            Map<String, dynamic> ingData = ingModel.toJson();
            ingData['recipe_id'] = newRecipeId;
            // 'ingredients' key in toJson now correctly holds the ingredient_text
            return ingData;
          })
          .toList();

      if (recipeIngredientsData.isNotEmpty) {
        await _supabase.from('recipe_ingredients').insert(recipeIngredientsData);
      }
      insertedRecipeData['recipe_ingredients'] = recipeModel.ingredients!.map((e) => e.toJson()).toList();
    }

    if (recipeModel.instructions != null && recipeModel.instructions!.isNotEmpty) {
      final List<Map<String, dynamic>> recipeInstructionsData = recipeModel.instructions!
          .map((instrModel) {
            Map<String, dynamic> instrData = instrModel.toJson();
            instrData['recipe_id'] = newRecipeId;
            // image_url is handled by instrModel.toJson()
            return instrData;
          })
          .toList();
      if (recipeInstructionsData.isNotEmpty) {
        await _supabase.from('recipe_instructions').insert(recipeInstructionsData);
      }
      insertedRecipeData['recipe_instructions'] = recipeModel.instructions!.map((e) => e.toJson()).toList();
    }

    return RecipeModel.fromJson(insertedRecipeData);
  }

  Future<RecipeModel> updateRecipe(RecipeModel recipeModel, List<String> newGalleryImageUrls) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (recipeModel.id == null) throw Exception('Recipe ID is required for update');

    final Map<String, dynamic> recipeData = recipeModel.toJson();
    recipeData['updated_at'] = DateTime.now().toIso8601String();
    recipeData.remove('id');
    recipeData.remove('user_id');
    recipeData.remove('created_at');
    recipeData.remove('gallery_image_urls');
    recipeData.remove('ingredients');
    recipeData.remove('instructions');
    recipeData.remove('ingredients_text');
    recipeData.remove('directions_text');

    final updatedRecipeData = await _supabase
        .from('recipes')
        .update(recipeData)
        .eq('id', recipeModel.id!)
        .select()
        .single();

    await _supabase.from('recipe_gallery_images').delete().eq('recipe_id', recipeModel.id!);
    if (newGalleryImageUrls.isNotEmpty) {
      final List<Map<String, dynamic>> galleryImagesData = newGalleryImageUrls
          .asMap()
          .entries
          .map((entry) => {
                'recipe_id': recipeModel.id!,
                'image_url': entry.value,
                'order_index': entry.key,
              })
          .toList();
      await _supabase.from('recipe_gallery_images').insert(galleryImagesData);
    }
    updatedRecipeData['gallery_image_urls'] = newGalleryImageUrls;

    await _supabase.from('recipe_ingredients').delete().eq('recipe_id', recipeModel.id!);
    if (recipeModel.ingredients != null && recipeModel.ingredients!.isNotEmpty) {
      final List<Map<String, dynamic>> recipeIngredientsData = recipeModel.ingredients!
          .map((ingModel) {
            Map<String, dynamic> ingData = ingModel.toJson();
            ingData['recipe_id'] = recipeModel.id!;
            return ingData;
          })
          .toList();
      if(recipeIngredientsData.isNotEmpty) {
        await _supabase.from('recipe_ingredients').insert(recipeIngredientsData);
      }
      updatedRecipeData['recipe_ingredients'] = recipeModel.ingredients!.map((e) => e.toJson()).toList();
    }

    await _supabase.from('recipe_instructions').delete().eq('recipe_id', recipeModel.id!);
    if (recipeModel.instructions != null && recipeModel.instructions!.isNotEmpty) {
      final List<Map<String, dynamic>> recipeInstructionsData = recipeModel.instructions!
          .map((instrModel) {
            Map<String, dynamic> instrData = instrModel.toJson();
            instrData['recipe_id'] = recipeModel.id!;
            return instrData;
          })
          .toList();
      if (recipeInstructionsData.isNotEmpty) {
        await _supabase.from('recipe_instructions').insert(recipeInstructionsData);
      }
      updatedRecipeData['recipe_instructions'] = recipeModel.instructions!.map((e) => e.toJson()).toList();
    }

    return RecipeModel.fromJson(updatedRecipeData);
  }
  
  Future<void> deleteRecipe(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Cascading deletes should handle related data in recipe_ingredients, recipe_instructions, etc.
    // if foreign keys are set up with ON DELETE CASCADE. Let's double check supabase_schema.sql.
    // recipe_ingredients: ON DELETE CASCADE for recipe_id - YES
    // recipe_instructions: ON DELETE CASCADE for recipe_id - YES
    // recipe_gallery_images: ON DELETE CASCADE for recipe_id - YES
    await _supabase.from('recipes').delete().eq('id', recipeId);
  }

  // addIngredientToRecipe and addInstructionToRecipe might become obsolete or be refactored
  // if all ingredients/instructions are managed through createRecipe/updateRecipe.
  // For now, I'll keep them but comment them out as their direct usage might conflict with the new flow.
  /*
  Future<void> addIngredientToRecipe({
    required int recipeId,
    required int ingredientId, // This assumes ingredientId is already known
    required double quantity,
    String? unit,
    String? notes,
    int orderIndex = 0,
  }) async {
    await _supabase
      .from('recipe_ingredients')
      .insert({
        'recipe_id': recipeId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit': unit,
        'notes': notes,
        'order_index': orderIndex,
      });
  }
  
  Future<void> addInstructionToRecipe({
    required int recipeId,
    required int stepNumber,
    required String instruction,
    String? imageUrl,
    int? estimatedTimeMinutes,
  }) async {
    await _supabase
      .from('recipe_instructions')
      .insert({
        'recipe_id': recipeId,
        'step_number': stepNumber,
        'instruction': instruction,
        'image_url': imageUrl,
        'estimated_time_minutes': estimatedTimeMinutes,
      });
  }
  */
  
  Future<void> toggleLikeRecipe(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final likes = await _supabase
      .from('recipe_likes')
      .select('id')
      .eq('user_id', userId)
      .eq('recipe_id', recipeId)
      .maybeSingle();
      
    if (likes == null) {
      await _supabase.from('recipe_likes').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    } else {
      await _supabase
        .from('recipe_likes')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
    }
  }

  /// Adds a comment to a recipe.
  /// Returns the newly created comment data including its ID and timestamps.
  Future<Map<String, dynamic>> addComment(int recipeId, String text, {int? parentCommentId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please log in to comment.');
    }

    final commentData = {
      'recipe_id': recipeId,
      'user_id': userId, // Use the authenticated user's ID
      'comment': text,
      'parent_comment_id': parentCommentId, // This will be null if not provided, which is fine
    };
    // Clean up null parent_comment_id if it wasn't provided, to avoid sending 'parent_comment_id': null
    if (parentCommentId == null) {
      commentData.remove('parent_comment_id');
    }


    final response = await _supabase
        .from('recipe_comments')
        .insert(commentData)
        .select('*, users (id, username, profile_picture)') // Also fetch user data for the new comment
        .single();

    return response;
  }

  Future<void> toggleCommentLike(String commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please log in to like comments.');
    }
    // Check if the like already exists
    final existingLike = await _supabase
        .from('comment_likes')
        .select('id')
        .eq('comment_id', int.parse(commentId)) // Assuming commentId in table is int
        .eq('user_id', userId) // Use the authenticated user's ID
        .maybeSingle();

    if (existingLike != null) {
      // Like exists, so delete it (unlike)
      await _supabase
          .from('comment_likes')
          .delete()
          .eq('id', existingLike['id']);
    } else {
      // Like doesn't exist, so insert it (like)
      await _supabase.from('comment_likes').insert({
        'comment_id': int.parse(commentId),
        'user_id': userId,
      });
    }
  }
}