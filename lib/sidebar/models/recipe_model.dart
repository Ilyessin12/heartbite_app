class RecipeModel {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final int? calories;
  final int servings;
  final int cookingTimeMinutes;
  final String difficultyLevel;
  final bool isPublished;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.calories,
    required this.servings,
    required this.cookingTimeMinutes,
    required this.difficultyLevel,
    required this.isPublished,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      calories: json['calories'],
      servings: json['servings'],
      cookingTimeMinutes: json['cooking_time_minutes'],
      difficultyLevel: json['difficulty_level'],
      isPublished: json['is_published'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
