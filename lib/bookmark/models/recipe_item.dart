class RecipeItem {
  final int? id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount; // This represents comment count
  final int likeCount; // This represents actual like count
  final int calories;
  final int prepTime;
  final int cookTime;

  RecipeItem({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.likeCount,
    required this.calories,
    required this.prepTime,
    required this.cookTime,
  }); // Factory constructor for creating from database data
  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipes'] ?? json;
    return RecipeItem(
      id: recipe['id'],
      name: recipe['title'] ?? recipe['name'] ?? '',
      imageUrl: recipe['image_url'] ?? '',
      rating: (recipe['rating'] ?? 0.0).toDouble(),
      reviewCount:
          recipe['comment_count'] ??
          recipe['review_count'] ??
          0, // Use comment_count for actual comments
      likeCount: recipe['like_count'] ?? 0, // Use like_count for actual likes
      calories: recipe['calories'] ?? 0,
      prepTime: recipe['prep_time'] ?? recipe['servings'] ?? 0,
      cookTime: recipe['cooking_time_minutes'] ?? recipe['cook_time'] ?? 0,
    );
  }

  // Factory constructor for creating from DisplayRecipeItem (homepage model)
  factory RecipeItem.fromDisplayRecipeItem(dynamic displayRecipe) {
    return RecipeItem(
      id: displayRecipe.id,
      name: displayRecipe.name,
      imageUrl: displayRecipe.imageUrl ?? '',
      rating: displayRecipe.rating,
      reviewCount: displayRecipe.reviewCount,
      likeCount: displayRecipe.likeCount,
      calories: displayRecipe.calories ?? 0,
      prepTime:
          displayRecipe.calories ??
          0, // Using calories as fallback for prepTime
      cookTime: displayRecipe.cookingTimeMinutes,
    );
  }

  // Factory constructor for creating from RecipeModel (sidebar model)
  factory RecipeItem.fromRecipeModel(dynamic recipeModel) {
    return RecipeItem(
      id: recipeModel.id,
      name: recipeModel.title,
      imageUrl: recipeModel.imageUrl ?? '',
      rating: recipeModel.rating,
      reviewCount: recipeModel.reviewCount,
      likeCount: recipeModel.likeCount,
      calories: recipeModel.calories ?? 0,
      prepTime: recipeModel.prepTime,
      cookTime: recipeModel.cookingTimeMinutes,
    );
  }
}
