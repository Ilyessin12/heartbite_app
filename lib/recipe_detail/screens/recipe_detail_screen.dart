import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List, Map; // Added
import 'dart:ui'; // Added
// import 'package:recipe_app/recipe/edit_recipe_screen.dart'; // EditRecipeScreen import removed
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/direction.dart';
import '../models/comment.dart';
import '../widgets/recipe_header.dart';
import '../widgets/ingredient_item.dart';
import '../widgets/direction_item.dart';
import '../widgets/comment_item.dart';
import '../widgets/gallery_grid.dart';
import '../utils/constants.dart';
import 'ingredients_screen.dart';
import 'gallery_screen.dart';
import 'bookmark_modal.dart';
import 'discussion_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;
  bool isBookmarked = false;
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;
  
  @override
  void initState() {
    super.initState();
    // Create a deep copy of the comments to avoid modifying the original list
    _comments = widget.recipe.comments.map((comment) => comment.copyWith()).toList();
  }
  
  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      // Add new comment at the beginning of the list with 0 likes
      _comments.insert(0, Comment.create(text: text));
    });
    _commentController.clear();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar removed, reverting to original structure where header controls were in the body.
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding( // This Padding and Row structure is from the original layout (before Edit button AppBar)
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row( // Favorite and Bookmark buttons back in their original place
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (isBookmarked) {
                              // If already bookmarked, remove bookmark
                              setState(() {
                                isBookmarked = false;
                              });
                            } else {
                              // If not bookmarked, show modal
                              _showBookmarkModal(context);
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50, // This outer container's color remains
                              shape: BoxShape.circle,
                            ),
                            // Replace Icon with new structure
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20), // Inner circle for blur effect
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  width: 40, // Ensure container fills the circle for consistent padding
                                  height: 40,
                                  padding: const EdgeInsets.all(0), // Reset padding if needed, icon has own size
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1), // Background for blurred area
                                    shape: BoxShape.circle, // Match outer shape
                                  ),
                                  child: Center( // Center the icon
                                    child: isBookmarked
                                        ? const BookmarkSolid(
                                            width: 24,
                                            height: 24,
                                            color: Colors.white,
                                          )
                                        : const Bookmark(
                                            width: 24,
                                            height: 24,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Edit IconButton and its logic removed from here (and from AppBar actions)
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeHeader(recipe: widget.recipe),
                    const SizedBox(height: 16),
                    
                    // Recipe stats
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.local_fire_department, "${widget.recipe.calories}", "Kalori"),
                          _buildStatItem(Icons.people_outline, widget.recipe.portions, "Porsi"),
                          _buildStatItem(Icons.timer, "${widget.recipe.cookingMinutes}", "Menit"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Ingredients section
                    _buildSectionHeader("Bahan-bahan", "${widget.recipe.ingredients.length} item"),
                    const SizedBox(height: 12),
                    ...widget.recipe.ingredients.map((ingredient) => 
                      IngredientItem(
                        ingredient: ingredient,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Directions section
                    _buildSectionHeader("Langkah-langkah", null),
                    const SizedBox(height: 12),
                    ...widget.recipe.directions.map((direction) => 
                      DirectionItem(
                        direction: direction,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start cooking button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngredientsScreen(recipe: widget.recipe),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Mulai Memasak",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Gallery section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Galeri",
                          style: AppTextStyles.subheading,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GalleryScreen(images: widget.recipe.galleryImages),
                              ),
                            );
                          },
                          child: const Text("lihat semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GalleryGrid(
                      images: widget.recipe.galleryImages,
                      onImageTap: (index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GalleryScreen(
                              images: widget.recipe.galleryImages,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      crossAxisCount: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Discussion section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Diskusi",
                          style: AppTextStyles.subheading,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiscussionScreen(
                                  comments: _comments,
                                  onCommentsUpdated: (updatedComments) {
                                    // Update comments when returning from discussion screen
                                    setState(() {
                                      _comments = updatedComments;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text("lihat semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._comments.take(3).map((comment) => 
                      CommentItem(
                        comment: comment,
                        onLike: (liked) {
                          setState(() {
                            final index = _comments.indexOf(comment);
                            if (index != -1) {
                              _comments[index] = comment.copyWith(
                                isLiked: liked,
                                likeCount: liked ? comment.likeCount + 1 : comment.likeCount - 1,
                              );
                            }
                          });
                        },
                        onReply: () {
                          // Handle reply
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Comment input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: "Diskusi di sini",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _addComment(_commentController.text);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.subheading,
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: AppTextStyles.caption,
          ),
      ],
    );
  }

  void _showBookmarkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkModal(
        onSave: (cookbookId) {
          setState(() {
            isBookmarked = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}