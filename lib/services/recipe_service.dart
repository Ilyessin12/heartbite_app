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
    var query = _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name)),
          recipe_gallery_images(id, image_url, caption, order_index)
        ''')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchPattern = '%${searchQuery.trim().replaceAll(' ', '%')}%';
      // Corrected usage of .or() filter for Supabase Flutter.
      // It takes a single string argument with conditions separated by commas.
      query = query.or('title.ilike.$searchPattern,description.ilike.$searchPattern');
    }
    
    final response = await query;
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

  /// Create new recipe using RecipeModel and handle gallery images.
  /// ingredients_text and directions_text from RecipeModel are currently not saved to separate tables in this version.
  Future<RecipeModel> createRecipe(RecipeModel recipeModel, List<String> galleryImageUrls) async {
    // user_id is now expected to be pre-set in recipeModel (hardcoded from CreateRecipeScreen)
    // final userId = _supabase.auth.currentUser?.id;
    // if (userId == null) throw Exception('User not authenticated');
    // recipeModel.user_id = userId; // No longer setting it from currentUser

    if (recipeModel.user_id.isEmpty) {
      throw Exception('User ID is missing in the recipe model.');
    }

    // Prepare data for 'recipes' table insertion
    final Map<String, dynamic> recipeData = recipeModel.toJson();

    // Remove fields not directly in 'recipes' table or handled separately
    recipeData.remove('id'); // id is auto-generated
    recipeData.remove('created_at'); // auto-generated
    recipeData.remove('updated_at'); // auto-generated
    recipeData.remove('gallery_image_urls'); // Handled separately
    recipeData.remove('ingredients_text'); // Not storing directly in 'recipes' table for now
    recipeData.remove('directions_text');  // Not storing directly in 'recipes' table for now

    final insertedRecipeData = await _supabase
        .from('recipes')
        .insert(recipeData)
        .select()
        .single();

    final newRecipeId = insertedRecipeData['id'] as int;

    // Handle gallery images
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

    // Return the full created recipe by fetching it again, or construct from insertedRecipeData
    // For simplicity, returning a model based on what was inserted + ID.
    // A more robust way would be to call getRecipeDetailsById(newRecipeId).
    insertedRecipeData['gallery_image_urls'] = galleryImageUrls; // Add back for the model
    return RecipeModel.fromJson(insertedRecipeData);
  }

  /// Update existing recipe using RecipeModel and handle gallery images.
  /// ingredients_text and directions_text are not updated in related tables in this version.
  Future<RecipeModel> updateRecipe(RecipeModel recipeModel, List<String> newGalleryImageUrls) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    if (recipeModel.id == null) throw Exception('Recipe ID is required for update');

    // Prepare data for 'recipes' table update
    final Map<String, dynamic> recipeData = recipeModel.toJson();
    recipeData['updated_at'] = DateTime.now().toIso8601String();

    // Remove fields not directly in 'recipes' table or handled separately/not updatable this way
    recipeData.remove('id');
    recipeData.remove('user_id'); // Should not change typically
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

    // Handle gallery images: Delete existing and insert new ones
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
  
  /// Delete a recipe by ID
  Future<void> deleteRecipe(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Optional: Check if the user owns the recipe before deleting
    // final recipe = await _supabase.from('recipes').select('user_id').eq('id', recipeId).single();
    // if (recipe['user_id'] != userId) throw Exception('User not authorized to delete this recipe');

    await _supabase.from('recipes').delete().eq('id', recipeId);
    // Related data in other tables (ingredients, instructions, gallery, likes, etc.)
    // should be configured with ON DELETE CASCADE in the database schema.
    // If not, they need to be deleted manually here.
    // supabase_schema.sql already has ON DELETE CASCADE for most relevant FKs.
  }


  // --- Existing methods (can be kept or refactored if needed) ---

  /// Add ingredient to recipe (kept for potential future use with structured ingredients)
  Future<void> addIngredientToRecipe({
    required int recipeId,
    required int ingredientId, // This implies an 'ingredients' table with IDs
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
  
  /// Add instruction to recipe (kept for potential future use with structured instructions)
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
  
  /// Like or unlike recipe
  Future<void> toggleLikeRecipe(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final likes = await _supabase
      .from('recipe_likes')
      .select('id') // Select only id for efficiency
      .eq('user_id', userId)
      .eq('recipe_id', recipeId)
      .maybeSingle(); // Use maybeSingle to avoid error if no like exists
      
    if (likes == null) {
      await _supabase.from('recipe_likes').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    } else {
      await _supabase
        .from('recipe_likes')
        .delete()
        .eq('user_id', userId) // For RLS, this might be implicit
        .eq('recipe_id', recipeId);
    }
  }
}