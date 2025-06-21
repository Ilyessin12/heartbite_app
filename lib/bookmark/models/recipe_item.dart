class RecipeItem {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int calories;
  final int prepTime;
  final int cookTime;

  RecipeItem({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.calories,
    required this.prepTime,
    required this.cookTime,
  });
}
