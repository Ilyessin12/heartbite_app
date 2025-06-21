import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';

class RecipeService {
  final _supabase = SupabaseClientWrapper().client;
  
  /// Get all public recipes
  Future<List<Map<String, dynamic>>> getPublicRecipes({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
  }) async {
  final query = _supabase
      .from('recipes')
      .select('''
        *,
        users(id, username, profile_picture),
        recipe_categories(category_id, categories(name))
      ''')
      .eq('is_published', true)
      .order('created_at', ascending: false)
      .limit(limit)
      .range(offset, offset + limit - 1);
        if (searchQuery != null && searchQuery.isNotEmpty) {
      // Buat query yang lebih sederhana untuk pencarian
      return await _supabase
        .from('recipes')
        .select('''
          *,
          users(id, username, profile_picture),
          recipe_categories(category_id, categories(name))
        ''')
        .eq('is_published', true)
        .or('title.ilike.%${searchQuery}%')
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);
    }
    
    return await query;
  }
  
  /// Get recipe details by ID
  Future<Map<String, dynamic>> getRecipeById(int recipeId) async {
    final recipe = await _supabase
      .from('recipes')
      .select('''
        *,
        users(id, username, profile_picture),
        recipe_categories(category_id, categories(name)),
        recipe_ingredients(
          id, quantity, unit, notes, order_index,
          ingredients(id, name, unit)
        ),
        recipe_instructions(id, step_number, instruction, image_url, estimated_time_minutes)
      ''')
      .eq('id', recipeId)
      .single();
      
    return recipe;
  }
  
  /// Create new recipe
  Future<Map<String, dynamic>> createRecipe({
    required String title,
    required String description,
    required int cookingTimeMinutes,
    required int servings,
    String? imageUrl,
    int? calories,
    String difficultyLevel = 'medium',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final recipe = await _supabase
      .from('recipes')
      .insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'cooking_time_minutes': cookingTimeMinutes,
        'servings': servings,
        'image_url': imageUrl,
        'calories': calories,
        'difficulty_level': difficultyLevel,
      })
      .select()
      .single();
      
    return recipe;
  }
  
  /// Add ingredient to recipe
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
  
  /// Add instruction to recipe
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
    
    // Check if already liked
    final likes = await _supabase
      .from('recipe_likes')
      .select()
      .eq('user_id', userId)
      .eq('recipe_id', recipeId);
      
    if (likes.isEmpty) {
      // Like recipe
      await _supabase.from('recipe_likes').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    } else {
      // Unlike recipe
      await _supabase
        .from('recipe_likes')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
    }
  }
}