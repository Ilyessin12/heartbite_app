import 'ingredient.dart';
import 'direction.dart';
import 'comment.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String authorName;
  final int authorRecipeCount;
  final int calories;
  final String portions; // Changed from prepTime to portions
  final int cookingMinutes;
  final List<Ingredient> ingredients;
  final List<Direction> directions;
  final List<String> galleryImages;
  final List<Comment> comments;

  // New fields for tags
  final List<String> allergenTags;
  final List<String> dietProgramTags;
  final List<String> equipmentTags;
  final String authorId; // Added authorId
  
  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.authorName,
    required this.authorRecipeCount,
    required this.calories,
    required this.portions, // Changed from prepTime to portions
    required this.cookingMinutes,
    required this.ingredients,
    required this.directions,
    required this.galleryImages,
    required this.comments,
    this.allergenTags = const [], // Default to empty list
    this.dietProgramTags = const [], // Default to empty list
    this.equipmentTags = const [], // Default to empty list
    required this.authorId, // Added authorId
  });
}