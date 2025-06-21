import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';
import '../models/recipe_model.dart'; // Import RecipeModel

class RecipeService {
  final _supabase = SupabaseClientWrapper().client;

  /// Get all public recipes with gallery images
  Future<List<Map<String, dynamic>>> getPublicRecipesWithDetails({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
  }) async {
    // Initialize query from 'recipes' table
    var queryBuilder = _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name)),
          recipe_gallery_images(id, image_url, caption, order_index)
        ''')
        .eq('is_published', true);

    // Apply .or() filter if searchQuery is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchPattern = '%${searchQuery.trim().replaceAll(' ', '%')}%';
      // .or() should be called on PostgrestFilterBuilder (result of .select().eq())
      queryBuilder = queryBuilder.or('title.ilike.$searchPattern,description.ilike.$searchPattern');
    }

    // Apply order, limit, and range after all filters
    final finalQuery = queryBuilder
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    final response = await finalQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get recipe details by ID including gallery images, ingredients, and instructions
  Future<Map<String, dynamic>> getRecipeDetailsById(int recipeId) async {
    final response = await _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name)),
          recipe_gallery_images(id, image_url, caption, order_index),
          recipe_ingredients(
            id, quantity, unit, notes, order_index,
            ingredients(id, name, unit)
          ),
          recipe_instructions(id, step_number, instruction, image_url, estimated_time_minutes)
        ''')
        .eq('id', recipeId)
        .single();
    return response;
  }

  Future<RecipeModel> createRecipe(RecipeModel recipeModel, List<String> galleryImageUrls) async {
    if (recipeModel.user_id.isEmpty) {
      throw Exception('User ID is missing in the recipe model.');
    }

    final Map<String, dynamic> recipeData = recipeModel.toJson();

    recipeData.remove('id');
    recipeData.remove('created_at');
    recipeData.remove('updated_at');
    recipeData.remove('gallery_image_urls');
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
    return RecipeModel.fromJson(updatedRecipeData);
  }
  
  Future<void> deleteRecipe(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('recipes').delete().eq('id', recipeId);
  }

  Future<void> addIngredientToRecipe({
    required int recipeId,
    required int ingredientId,
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
}