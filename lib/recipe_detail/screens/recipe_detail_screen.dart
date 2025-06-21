import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List, Map;
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase User
import '../../models/recipe_model.dart' as SupabaseRecipeModel; // Alias for Supabase model
import '../../recipe/edit_recipe_screen.dart'; // Import EditRecipeScreen
import '../../services/recipe_service.dart'; // Import RecipeService
import '../../services/supabase_client.dart'; // For current user
import '../models/recipe.dart' as DetailModel; // Alias for local detail model
import '../models/ingredient.dart' as DetailModelIngredient;
import '../models/direction.dart' as DetailModelDirection;
import '../models/comment.dart' as DetailModelComment;
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
  final int recipeId; // Changed to accept recipeId
  
  const RecipeDetailScreen({
    super.key,
    required this.recipeId, // Changed to recipeId
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  DetailModel.Recipe? _recipe; // Nullable, will be fetched
  bool _isLoading = true;
  String _loadingError = '';

  bool isFavorite = false;
  bool isBookmarked = false;
  final TextEditingController _commentController = TextEditingController();
  List<DetailModelComment.Comment> _comments = []; // Initialize as empty
  
  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    setState(() {
      _isLoading = true;
      _loadingError = '';
    });
    try {
      final recipeData = await _recipeService.getRecipeDetailsById(widget.recipeId);
      // Adapt recipeData (Map<String, dynamic>) to DetailModel.Recipe
      // This is a complex mapping due to different structures and related tables
      setState(() {
        _recipe = _adaptSupabaseDataToDetailModel(recipeData);
        _comments = _recipe?.comments.map((c) => c.copyWith()).toList() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching recipe details: $e");
      setState(() {
        _isLoading = false;
        _loadingError = "Gagal memuat detail resep: ${e.toString()}";
      });
    }
  }

  DetailModel.Recipe _adaptSupabaseDataToDetailModel(Map<String, dynamic> data) {
    // User data (author)
    final Map<String, dynamic>? userData = data['users'] as Map<String, dynamic>?;

    // Ingredients
    final List<dynamic> ingredientsData = data['recipe_ingredients'] as List<dynamic>? ?? [];
    final List<DetailModelIngredient.Ingredient> ingredients = ingredientsData.map((ingData) {
      final Map<String, dynamic> actualIngredient = ingData['ingredients'] as Map<String, dynamic>? ?? {};
      return DetailModelIngredient.Ingredient(
        order: ingData['order_index'] as int? ?? ingredientsData.indexOf(ingData),
        name: actualIngredient['name'] as String? ?? 'Unknown Ingredient',
        amount: (ingData['quantity'] as num?)?.toString() ?? '0',
        unit: ingData['unit'] as String? ?? actualIngredient['unit'] as String? ?? '',
      );
    }).toList().cast<DetailModelIngredient.Ingredient>();

    // Directions
    final List<dynamic> instructionsData = data['recipe_instructions'] as List<dynamic>? ?? [];
    final List<DetailModelDirection.Direction> directions = instructionsData.map((instData) {
      return DetailModelDirection.Direction(
        order: instData['step_number'] as int? ?? 0,
        description: instData['instruction'] as String? ?? '',
        imageUrl: instData['image_url'] as String?,
      );
    }).toList().cast<DetailModelDirection.Direction>();

    // Gallery Images
    final List<dynamic> galleryData = data['recipe_gallery_images'] as List<dynamic>? ?? [];
    final List<String> galleryImages = galleryData
        .map((galItem) => galItem['image_url'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();

    // Comments (basic structure, assuming comments are not deeply nested or fetched here)
    // This part would need more complex logic if comments are fetched with likes, replies etc.
    // For now, we'll assume comments are not part of the initial getRecipeDetailsById or are simple.
    final List<DetailModelComment.Comment> comments = []; // Placeholder, fetch separately or adapt

    return DetailModel.Recipe(
      id: data['id'].toString(), // DetailModel expects String ID
      title: data['title'] as String? ?? 'No Title',
      imageUrl: data['image_url'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      authorName: userData?['username'] as String? ?? 'Unknown Author',
      authorRecipeCount: 0, // This info is not directly in users table, might need another query or be omitted
      calories: data['calories'] as int? ?? 0,
      portions: "${data['servings'] as int? ?? 1} Porsi",
      cookingMinutes: data['cooking_time_minutes'] as int? ?? 0,
      ingredients: ingredients,
      directions: directions,
      galleryImages: galleryImages,
      comments: comments, // Initialize with empty or fetched comments
    );
  }
  
  void _addComment(String text) {
    if (text.trim().isEmpty || _recipe == null) return;
    
    // TODO: Implement actual comment saving to Supabase
    // For now, just updating local state
    setState(() {
      _comments.insert(0, DetailModelComment.Comment.create(text: text));
    });
    _commentController.clear();
    // After Supabase call, you might want to call _fetchRecipeDetails() or update locally
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  void _navigateToEditScreen() async {
    if (_recipe == null) return;

    // Adapt DetailModel.Recipe to SupabaseRecipeModel.RecipeModel for EditRecipeScreen
    // This requires careful mapping.
    SupabaseRecipeModel.RecipeModel recipeToEdit = SupabaseRecipeModel.RecipeModel(
        id: int.tryParse(_recipe!.id), // Supabase model has int id
        user_id: SupabaseClientWrapper().auth.currentUser?.id ?? "", // This should be the actual recipe owner's ID
        title: _recipe!.title,
        description: "", // DetailModel.Recipe doesn't have a direct description field, map accordingly
        image_url: _recipe!.imageUrl,
        calories: _recipe!.calories,
        servings: int.tryParse(_recipe!.portions.split(" ").first) ?? 1, // Extract number from "X Porsi"
        cooking_time_minutes: _recipe!.cookingMinutes,
        difficulty_level: "medium", // DetailModel.Recipe doesn't have this, provide default or map
        is_published: true, // Assuming it's published, or get this state from fetched data
        gallery_image_urls: _recipe!.galleryImages,
        // ingredients_text and directions_text are reconstructed from DetailModel
        ingredients_text: _recipe!.ingredients.map((e) => "${e.amount} ${e.unit} ${e.name}").join('\n'), // Used e.amount
        directions_text: _recipe!.directions.map((e) => e.description).join('\n'),
    );

    // Authorization check already happens in EditRecipeScreen using recipeToEdit.user_id
    // We must ensure recipeToEdit.user_id is the *original creator's ID*.
    // The current logic in _adaptSupabaseDataToDetailModel does not explicitly set user_id on _recipe object.
    // Let's assume getRecipeDetailsById returns user_id in the top-level map.
    final Map<String, dynamic>? originalRecipeDataFromServer = await _recipeService.getRecipeDetailsById(widget.recipeId);
    final originalCreatorId = originalRecipeDataFromServer?['user_id'] as String?;

    if (originalCreatorId == null || originalCreatorId.isEmpty) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not verify recipe owner.')));
        }
        return;
    }
    recipeToEdit.user_id = originalCreatorId; // Set the correct original creator's ID for EditRecipeScreen to check

    // Now, perform the navigation with the correctly populated recipeToEdit
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditRecipeScreen(recipe: recipeToEdit)),
    );
    if (result == true) {
      _fetchRecipeDetails(); // Refresh details if changes were made
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Loading Recipe...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadingError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(_loadingError, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Recipe Not Found")),
        body: const Center(child: Text("Could not load recipe details.")),
      );
    }

    // User for checking ownership for edit button
    final currentUser = SupabaseClientWrapper().auth.currentUser;


    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false), // Pass false if no changes
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
                    Row(
                      children: [
                         // Edit Button - Show only if current user is the owner
                        if (currentUser != null && _recipe!.id.isNotEmpty) // Basic check, improve with actual user_id from recipe
                          FutureBuilder<Map<String, dynamic>>(
                            future: _recipeService.getRecipeDetailsById(int.parse(_recipe!.id)), // Re-fetch to get user_id
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data?['user_id'] == currentUser.id) {
                                return GestureDetector(
                                  onTap: _navigateToEditScreen,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: AppColors.primary),
                                  ),
                                );
                              }
                              return const SizedBox.shrink(); // Don't show if not owner or still loading user_id
                            }
                          ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                              // TODO: Implement Supabase like/unlike logic
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
                              setState(() {
                                isBookmarked = false;
                                // TODO: Implement Supabase unbookmark logic
                              });
                            } else {
                              _showBookmarkModal(context); // Shows modal to select folder
                                                          // Actual bookmarking to Supabase happens in modal's onSave
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
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
                    RecipeHeader(recipe: _recipe!),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.local_fire_department, "${_recipe!.calories}", "Kalori"),
                          _buildStatItem(Icons.people_outline, _recipe!.portions, "Porsi"),
                          _buildStatItem(Icons.timer, "${_recipe!.cookingMinutes}", "Menit"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader("Bahan-bahan", "${_recipe!.ingredients.length} item"),
                    const SizedBox(height: 12),
                    ..._recipe!.ingredients.map((ingredient) =>
                      IngredientItem(
                        ingredient: ingredient,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildSectionHeader("Langkah-langkah", null),
                    const SizedBox(height: 12),
                    ..._recipe!.directions.map((direction) =>
                      DirectionItem(
                        direction: direction,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                           if (_recipe == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngredientsScreen(recipe: _recipe!),
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