import 'recipe_item.dart';

class BookmarkCategory {
  final String name;
  final String imageUrl;
  final List<RecipeItem> recipes;
  bool isSelected;

  BookmarkCategory({
    required this.name,
    required this.imageUrl,
    required this.recipes,
    this.isSelected = false,
  });
}
