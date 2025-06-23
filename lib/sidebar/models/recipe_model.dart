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
  final int prepTime;
  final int likeCount; // This represents actual like count
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
    required this.prepTime,
    required this.likeCount,
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
      prepTime: json['prep_time'] ?? json['servings'] ?? 0,
      likeCount: json['like_count'] ?? 0, // Use like_count for actual likes
      difficultyLevel: json['difficulty_level'],
      isPublished: json['is_published'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount:
          json['comment_count'] ??
          json['review_count'] ??
          0, // Use comment_count for actual comments
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
