import 'recipe_item.dart';

class BookmarkCategory {
  final int? id;
  final String name;
  String imageUrl;
  final List<RecipeItem> recipes;
  bool isSelected;

  BookmarkCategory({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.recipes,
    this.isSelected = false,
  });

  // Factory constructor for creating from database data
  factory BookmarkCategory.fromJson(Map<String, dynamic> json) {
    return BookmarkCategory(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'] ?? '',
      recipes: [], // Will be loaded separately
    );
  }

  // It's also a good practice to add fromJson and toJson methods
  // for easy conversion between Dart objects and database records.
}
