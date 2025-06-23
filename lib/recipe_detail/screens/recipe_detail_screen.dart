import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:iconoir_flutter/iconoir_flutter.dart'
    hide Key, Text, Navigator, List, Map;
import 'dart:ui';
import '../../models/recipe_model.dart'
    as supabase_recipe_model; // Alias for Supabase model
import '../../recipe/edit_recipe_screen.dart'; // Import EditRecipeScreen
import '../../services/recipe_service.dart'; // Import RecipeService
import '../../services/bookmark_service.dart'; // Import BookmarkService
import '../../services/supabase_client.dart'; // For current user
import '../../services/auth_service.dart'; // Added import
import '../models/recipe.dart' as detail_model; // Alias for local detail model
import '../models/ingredient.dart' as detail_model_ingredient;
import '../models/direction.dart' as detail_model_direction;
import '../models/comment.dart' as detail_model_comment;
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
  final BookmarkService _bookmarkService = BookmarkService();
  detail_model.Recipe? _recipe; // Nullable, will be fetched
  bool _isLoading = true;
  String _loadingError = '';

  bool _isFavorite = false; // Renamed to avoid conflict with Icon
  int _likeCount = 0; // To store like count
  bool isBookmarked = false;
  final TextEditingController _commentController = TextEditingController();
  List<detail_model_comment.Comment> _comments = []; // Initialize as empty
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetailsAndLikes();
    _checkBookmarkStatus();
  }

  Future<void> _fetchRecipeDetailsAndLikes() async {
    await _fetchRecipeDetails(); // Fetch main details first
    if (_recipe != null) { // Only fetch likes if recipe loaded
      _checkIfFavorite();
      _fetchLikeCount();
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favorited = await _recipeService.isRecipeLikedByUser(widget.recipeId);
      if (mounted) {
        setState(() {
          _isFavorite = favorited;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if recipe is favorited: $e');
      }
      // Optionally show a snackbar or handle error
    }
  }

  Future<void> _fetchLikeCount() async {
    try {
      final count = await _recipeService.getRecipeLikeCount(widget.recipeId);
      if (mounted) {
        setState(() {
          _likeCount = count;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching like count: $e');
      }
      // Optionally show a snackbar or handle error
    }
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final bookmarked = await _bookmarkService.isRecipeBookmarked(
        widget.recipeId,
      );
      setState(() {
        isBookmarked = bookmarked;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking bookmark status: $e');
      }
    }
  }

  Future<void> _showRemoveBookmarkDialog() async {
    try {
      // Get folders where this recipe is bookmarked
      final folders = await _bookmarkService.getRecipeBookmarkFolders(
        widget.recipeId,
      );

      if (folders.isEmpty) {
        setState(() {
          isBookmarked = false;
        });
        return;
      }

      // Show dialog to remove from specific folders
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove Bookmark'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This recipe is bookmarked in:'),
                    const SizedBox(height: 8),
                    ...folders.map(
                      (folder) => ListTile(
                        title: Text(folder['bookmark_folders']['name']),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            try {
                              await _bookmarkService.removeBookmarkFromFolder(
                                recipeId: widget.recipeId,
                                folderId: folder['folder_id'],
                              );
                               if (mounted) Navigator.pop(context); // Guard with mounted check
                              _checkBookmarkStatus(); // Refresh bookmark status
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bookmark removed successfully!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                               if (kDebugMode) {
                                 print('Error removing bookmark: $e');
                               }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                       'Error removing bookmark: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                     onPressed: () {
                       if (mounted) Navigator.pop(context);
                     },
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
       if (kDebugMode) {
         print('Error getting bookmark folders: $e');
       }
    }
  }

  Future<void> _fetchRecipeDetails() async {
    setState(() {
      _isLoading = true;
      _loadingError = '';
    });
    try {
      // Dynamically get the current user's ID. It can be null if no user is logged in.
      final String? currentUserId = SupabaseClientWrapper().client.auth.currentUser?.id;
      
      final recipeData = await _recipeService.getRecipeDetailsById(
        widget.recipeId,
        currentUserId: currentUserId, // Pass the dynamic (possibly null) user ID
      );

      if (!mounted) return; // Check if the widget is still in the tree

      // Adapt recipeData (Map<String, dynamic>) to detail_model.Recipe
      // This is a complex mapping due to different structures and related tables
      setState(() {
      _recipe = _adaptSupabaseDataToDetailModel(recipeData, recipeData['user_id'] as String?);
        _comments = _recipe?.comments.map((c) => c.copyWith()).toList() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching recipe details: $e");
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingError = "Gagal memuat detail resep: ${e.toString()}";
        });
      }
    }
  }

  detail_model.Recipe _adaptSupabaseDataToDetailModel(
    Map<String, dynamic> data,
    String? authorId, // Added authorId parameter
  ) {
    // Description
    final String description = data['description'] as String? ?? 'No description available.';

    // User data (author)
    final Map<String, dynamic>? userData =
        data['users'] as Map<String, dynamic>?;

    // Ingredients
    final List<dynamic> ingredientsData =
        data['recipe_ingredients'] as List<dynamic>? ?? [];
    final List<detail_model_ingredient.Ingredient> ingredients =
        ingredientsData
            .map((ingDataMap) {
              // Ensure ingDataMap is actually a map
              if (ingDataMap is Map<String, dynamic>) {
                // The 'ingredients' field from the database IS the name.
                final String ingredientName =
                    ingDataMap['ingredients'] as String? ??
                    'Unknown Ingredient';
                return detail_model_ingredient.Ingredient(
                  order:
                      ingDataMap['order_index'] as int? ??
                      ingredientsData.indexOf(ingDataMap),
                  name: ingredientName, // Use the direct string
                  amount: (ingDataMap['quantity'] as num?)?.toString() ?? '0',
                  unit: ingDataMap['unit'] as String? ?? '',
                );
              } else {
                // Handle case where an item in ingredientsData is not a map
                if (kDebugMode) {
                  print(
                    "WARNING: Skipping non-map item in ingredientsData: $ingDataMap",
                  );
                }
                return null;
              }
            })
            .whereType<detail_model_ingredient.Ingredient>()
            .toList(); // Filter out any nulls

    // Directions
    final List<dynamic> instructionsData =
        data['recipe_instructions'] as List<dynamic>? ?? [];
    final List<detail_model_direction.Direction> directions =
        instructionsData
            .map((instData) {
              return detail_model_direction.Direction(
                order: instData['step_number'] as int? ?? 0,
                description: instData['instruction'] as String? ?? '',
                imageUrl: instData['image_url'] as String?,
              );
            })
            .toList()
            .cast<detail_model_direction.Direction>();

    // Gallery Images
    final List<dynamic> galleryData =
        data['recipe_gallery_images'] as List<dynamic>? ?? [];
    final List<String> galleryImages =
        galleryData
            .map((galItem) => galItem['image_url'] as String?)
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();

    // Comments
    final List<dynamic> fetchedCommentsData = data['recipe_comments'] as List<dynamic>? ?? [];
    final List<detail_model_comment.Comment> flatComments = fetchedCommentsData
        .map((commentJson) => detail_model_comment.Comment.fromJson(commentJson as Map<String, dynamic>))
        .toList();
    
    // Structure comments into threads
    final Map<String, detail_model_comment.Comment> commentMap = {
      for (var comment in flatComments) comment.id: comment
    };
    final List<detail_model_comment.Comment> topLevelComments = [];

    for (var comment in flatComments) {
      if (comment.parentCommentId != null) {
        // It's a reply, find its parent
        final parent = commentMap[comment.parentCommentId.toString()];
        if (parent != null) {
          parent.replies.add(comment);
        } else {
          // Orphaned reply
          if (kDebugMode) {
            print('Warning: Orphaned reply found with id: ${comment.id}, parent_id: ${comment.parentCommentId}');
          }
          topLevelComments.add(comment);
        }
      } else {
        // It's a top-level comment
        topLevelComments.add(comment);
      }
    }

    return detail_model.Recipe(
      id: data['id'].toString(), // detail_model expects String ID
      title: data['title'] as String? ?? 'No Title',
      imageUrl: data['image_url'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      authorName: userData?['username'] as String? ?? 'Unknown Author',
      authorRecipeCount:
          0, // This info is not directly in users table, might need another query or be omitted
      calories: data['calories'] as int? ?? 0,
      portions: "${data['servings'] as int? ?? 1} Porsi",
      cookingMinutes: data['cooking_time_minutes'] as int? ?? 0,
      ingredients: ingredients,
      directions: directions,
      galleryImages: galleryImages,
      comments: topLevelComments, // Pass the structured, top-level comments
      authorId: authorId ?? '', // Store authorId
      description: description, // Add description

      // Extract tag names
      allergenTags: (data['allergens'] as List<dynamic>?)
          ?.map((tag) => (tag as Map<String, dynamic>)['name'] as String)
          .toList() ?? [],
      dietProgramTags: (data['diet_programs'] as List<dynamic>?)
          ?.map((tag) => (tag as Map<String, dynamic>)['name'] as String)
          .toList() ?? [],
      equipmentTags: (data['equipment'] as List<dynamic>?)
          ?.map((tag) => (tag as Map<String, dynamic>)['name'] as String)
          .toList() ?? [],
    );
  }

  void _addComment(String text) async { // Make async
    if (text.trim().isEmpty || _recipe == null) return;

    final currentUser = SupabaseClientWrapper().client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to add a comment.")),
        );
      }
      return;
    }

    // final String currentUserId = "325c40cc-d255-4f93-bf5f-40bc196ca093"; // Hardcoded User ID for now
    final int recipeId = int.tryParse(_recipe!.id) ?? 0;
    final int? parentId = _replyingToCommentId != null ? int.tryParse(_replyingToCommentId!) : null;

    if (recipeId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Invalid recipe ID.")),
        );
      }
      return;
    }

    try {
      // RecipeService.addComment will get the userId from currentUser
      final newCommentData = await _recipeService.addComment(
        recipeId,
        // currentUserId, // No longer pass userId, service will get it
        text.trim(),
        parentCommentId: parentId,
      );
      if (!mounted) return; // Guard after await

      final newComment = detail_model_comment.Comment.fromJson(newCommentData);

      setState(() {
        if (newComment.parentCommentId != null) {
          // This is a reply, add it to the parent's replies list
          final added = _addReplyToLocalList(_comments, newComment);
          if (!added) {
            // Parent not found, fallback to add as a top-level comment or handle error
            if (kDebugMode) {
              print("Error: Parent comment not found for reply. Adding as top-level.");
            }
            _comments.insert(0, newComment);
          }
        } else {
          // This is a top-level comment
          _comments.insert(0, newComment); // Add to the beginning for newest first
        }
        _replyingToCommentId = null; // Reset reply state
        _replyingToUserName = null;
      });
      _commentController.clear();

    } catch (e) {
      if (kDebugMode) {
        print("Error adding comment: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add comment: ${e.toString()}")),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _initiateReply(detail_model_comment.Comment parentComment) {
    setState(() {
      _replyingToCommentId = parentComment.id;
      _replyingToUserName = parentComment.userName;
      // TODO: Optionally, focus the text field and set text like "@username "
      // FocusScope.of(context).requestFocus(_commentFocusNode); // Assuming you have a FocusNode for the TextField
      // _commentController.text = "@${parentComment.userName} ";
    });
  }

  // Helper function to recursively find and add a reply to the local list
  bool _addReplyToLocalList(List<detail_model_comment.Comment> commentsList, detail_model_comment.Comment reply) {
    for (var comment in commentsList) {
      if (comment.id == reply.parentCommentId.toString()) {
        comment.replies.insert(0, reply); 
        return true; 
      }
      if (comment.replies.isNotEmpty) {
        if (_addReplyToLocalList(comment.replies, reply)) {
          return true; 
        }
      }
    }
    return false; 
  }

  detail_model_comment.Comment? _findAndUpdateComment(
    List<detail_model_comment.Comment> commentsList,
    String commentId,
    detail_model_comment.Comment Function(detail_model_comment.Comment) updater,
  ) {
    for (int i = 0; i < commentsList.length; i++) {
      var comment = commentsList[i];
      if (comment.id == commentId) {
        commentsList[i] = updater(comment);
        return commentsList[i];
      }
      if (comment.replies.isNotEmpty) {
        final updatedInReply = _findAndUpdateComment(comment.replies, commentId, updater);
        if (updatedInReply != null) return updatedInReply;
      }
    }
    return null;
  }

  Future<void> _handleCommentLike(detail_model_comment.Comment commentToToggle) async {
    // final String currentUserId = "325c40cc-d255-4f93-bf5f-40bc196ca093"; // Hardcoded User ID
    final currentUser = SupabaseClientWrapper().client.auth.currentUser;

    if (currentUser == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to like comments.")),
        );
      }
      return;
    }

    // Optimistic UI update
    setState(() {
      _findAndUpdateComment(_comments, commentToToggle.id, (comment) {
        return comment.copyWith(
          isLiked: !comment.isLiked,
          likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
        );
      });
    });

    try {
      // toggleCommentLike in service will get current user ID
      await _recipeService.toggleCommentLike(commentToToggle.id);
    } catch (e) {
      if (kDebugMode) {
        print("Error toggling comment like: $e");
      }
      // Revert UI update on error
      if(mounted) { // Guard setState with mounted check
        setState(() {
          _findAndUpdateComment(_comments, commentToToggle.id, (comment) {
            return comment.copyWith(
              isLiked: !comment.isLiked, 
              likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1, 
            );
          });
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update like status: ${e.toString()}")),
        );
      }
    }
  }

  void _navigateToEditScreen() async {
    if (_recipe == null) return;

    // Adapt detail_model.Recipe to supabase_recipe_model.RecipeModel for EditRecipeScreen
    // This requires careful mapping.
    supabase_recipe_model.RecipeModel
    recipeToEdit = supabase_recipe_model.RecipeModel(
      id: int.tryParse(_recipe!.id), // Supabase model has int id
      user_id:
          SupabaseClientWrapper().auth.currentUser?.id ??
          "", // This should be the actual recipe owner's ID
      title: _recipe!.title,
      description:
          _recipe!.description, // Use description from detail_model.Recipe
      image_url: _recipe!.imageUrl,
      calories: _recipe!.calories,
      servings:
          int.tryParse(_recipe!.portions.split(" ").first) ??
          1, // Extract number from "X Porsi"
      cooking_time_minutes: _recipe!.cookingMinutes,
      difficulty_level:
          "medium", // detail_model.Recipe doesn't have this, provide default or map
      is_published:
          true, // Assuming it's published, or get this state from fetched data
      gallery_image_urls: _recipe!.galleryImages,
      // ingredients_text and directions_text are reconstructed from detail_model
      ingredients_text: _recipe!.ingredients
          .map((e) => "${e.amount} ${e.unit} ${e.name}")
          .join('\n'), // Used e.amount
      directions_text: _recipe!.directions.map((e) => e.description).join('\n'),
    );

    // Authorization check already happens in EditRecipeScreen using recipeToEdit.user_id
    // We must ensure recipeToEdit.user_id is the *original creator's ID*.
    // The current logic in _adaptSupabaseDataToDetailModel does not explicitly set user_id on _recipe object.
    // Let's assume getRecipeDetailsById returns user_id in the top-level map.
    final Map<String, dynamic>? originalRecipeDataFromServer =
        await _recipeService.getRecipeDetailsById(widget.recipeId);
    
    if (!mounted) return; // Guard after await

    final originalCreatorId =
        originalRecipeDataFromServer?['user_id'] as String?;

    if (originalCreatorId == null || originalCreatorId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not verify recipe owner.')),
        );
      }
      return;
    }
    recipeToEdit.user_id =
        originalCreatorId; // Set the correct original creator's ID for EditRecipeScreen to check

    // Now, perform the navigation, passing only the recipeId
    if (_recipe == null || _recipe!.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Recipe ID not available to edit.')),
        );
      }
      return;
    }

    final int? recipeIdToInt = int.tryParse(_recipe!.id);
    if (recipeIdToInt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid Recipe ID format.')),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipeId: recipeIdToInt), // Pass recipeId
      ),
    );
    if (result == true && mounted) { // Guard with mounted check
      _fetchRecipeDetails(); // Refresh details if changes were made
    }
  }

  Future<void> _deleteRecipe() async {
    if (_recipe == null || _recipe!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Recipe ID tidak tersedia untuk dihapus.')),
      );
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus resep ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final recipeId = int.tryParse(_recipe!.id);
        if (recipeId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Format ID Resep tidak valid.')),
          );
          return;
        }
        await _recipeService.deleteRecipe(recipeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resep berhasil dihapus!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Pop with true to indicate success/change
      } catch (e) {
        print('Error deleting recipe: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus resep: ${e.toString()}')),
        );
      }
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
        body: Center(
          child: Text(_loadingError, style: const TextStyle(color: Colors.red)),
        ),
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
                      onTap: () {
                        if (mounted) {
                          Navigator.pop(
                            context,
                            false,
                          ); // Pass false if no changes
                        }
                      },
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
                        if (currentUser != null &&
                            _recipe!
                                .id
                                .isNotEmpty) // Basic check, improve with actual user_id from recipe
                          FutureBuilder<Map<String, dynamic>>(
                            future: _recipeService.getRecipeDetailsById(
                              int.parse(_recipe!.id),
                            ), // Re-fetch to get user_id
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data?['user_id'] == currentUser.id) {
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
                                    child: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink(); // Don't show if not owner or still loading user_id
                            },
                          ),
                        // Delete Button - Show only if current user is the owner
                        if (currentUser != null &&
                            _recipe!
                                .id
                                .isNotEmpty) 
                          FutureBuilder<Map<String, dynamic>>(
                            future: _recipeService.getRecipeDetailsById(
                              int.parse(_recipe!.id),
                            ), // Re-fetch to get user_id
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data?['user_id'] == currentUser.id) {
                                return GestureDetector(
                                  onTap: _deleteRecipe, // Call delete function
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50, // Different color for delete
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink(); // Don't show if not owner
                            },
                          ),
                        GestureDetector(
                          onTap: () async {
                            final localCurrentUser = SupabaseClientWrapper().client.auth.currentUser; // Use a local variable
                            if (localCurrentUser == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please log in to like recipes.")),
                                );
                              }
                              return;
                            }
                            if (_recipe == null) return;
                            final currentRecipeId = int.tryParse(_recipe!.id);
                            if (currentRecipeId == null) return;

                            // Optimistic UI update
                            setState(() {
                              _isFavorite = !_isFavorite;
                              if (_isFavorite) {
                                _likeCount++;
                              } else {
                                _likeCount--;
                              }
                            });

                            try {
                              await _recipeService.toggleLikeRecipe(currentRecipeId);
                              // After server confirmation, refresh the like count and status
                              // to ensure consistency, though optimistic update handles immediate UI.
                              if(mounted) { // Guard async calls that might update state
                                _fetchLikeCount(); 
                                _checkIfFavorite(); 
                              }
                            } catch (e) {
                              // Revert UI on error
                              if(mounted) { // Guard setState with mounted check
                                setState(() {
                                  _isFavorite = !_isFavorite; // Toggle back
                                  if (_isFavorite) { // This means it was false before, and we are reverting the increment
                                    _likeCount++;
                                  } else { // This means it was true before, and we are reverting the decrement
                                    _likeCount--;
                                  }
                                });
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to update like: ${e.toString()}")),
                                );
                              }
                              if (kDebugMode) {
                                print("Error toggling recipe like: $e");
                              }
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFavorite // Use the new state variable
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _isFavorite ? AppColors.primary : Colors.grey, // Use the new state variable
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (!AuthService.isUserLoggedIn()) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please log in to bookmark recipes.")),
                                );
                              }
                              return;
                            }
                            if (isBookmarked) {
                              _showRemoveBookmarkDialog(); // Shows dialog to remove from specific folders
                            } else {
                              _showBookmarkModal(
                                context,
                              ); // Shows modal to select folder
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
                                    color: Colors.black.withOpacity(0.1), // Keep withOpacity for now, or replace with .withValues() if specific control is needed
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child:
                                        isBookmarked
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
                    RecipeHeader(
                      recipe: _recipe!,
                      likeCount: _likeCount,
                      isFavorite: _isFavorite,
                      authorId: _recipe!.authorId, // Pass authorId
                    ),
                    const SizedBox(height: 16),
                    // Display Description
                    Text(
                      _recipe!.description,
                      style: AppTextStyles.body, // This should now be defined
                    ),
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
                          // _buildStatItem( // Removed Suka/Likes from here, it's now in RecipeHeader
                          //   Icons.favorite, 
                          //   "$_likeCount", 
                          //   "Suka", 
                          // ),
                          _buildStatItem(
                            Icons.local_fire_department,
                            "${_recipe!.calories}",
                            "Kalori",
                          ),
                          _buildStatItem(
                            Icons.people_outline,
                            _recipe!.portions,
                            "Porsi",
                          ),
                          _buildStatItem( // Restoring Timer/Cooking Time
                            Icons.timer,
                            "${_recipe!.cookingMinutes}",
                            "Menit",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(
                      "Bahan-bahan",
                      "${_recipe!.ingredients.length} bahan",
                    ),
                    const SizedBox(height: 12),
                    ..._recipe!.ingredients.map(
                      (ingredient) => IngredientItem(
                        ingredient: ingredient,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader("Langkah-langkah", null),
                    const SizedBox(height: 12),
                    ..._recipe!.directions.map(
                      (direction) => DirectionItem(
                        direction: direction,
                        showCheckbox: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display Tags
                    _buildTagsSection("Alergi", _recipe!.allergenTags),
                    _buildTagsSection("Program Diet", _recipe!.dietProgramTags),
                    _buildTagsSection("Alat-alat yang dibutuhkan", _recipe!.equipmentTags),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_recipe == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IngredientsScreen(
                                recipe: _recipe!,
                                likeCount: _likeCount,
                                isFavorite: _isFavorite,
                                authorId: _recipe!.authorId, // Pass authorId
                              ),
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
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gallery section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Galeri", style: AppTextStyles.subheading),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => GalleryScreen(
                                      images: _recipe!.galleryImages,
                                    ),
                              ),
                            );
                          },
                          child: const Text("lihat semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GalleryGrid(
                      images: _recipe!.galleryImages, 
                      onImageTap: (index) {
                        if(mounted) { // Guard Navigator.push
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => GalleryScreen(
                                    images:
                                        _recipe!
                                            .galleryImages, 
                                    initialIndex: index,
                                  ),
                            ),
                          );
                        }
                      },
                      crossAxisCount: 3,
                    ),
                    const SizedBox(height: 24),

                    // Discussion section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Diskusi", style: AppTextStyles.subheading),
                        TextButton(
                          onPressed: () {
                            if(mounted) { // Guard Navigator.push
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    // Ensure _recipe and _recipe.id are not null and _recipe.id is parseable to int
                                    if (_recipe == null || _recipe!.id.isEmpty) {
                                      // Handle error case, maybe show a dialog or return an error widget
                                      return Scaffold(
                                        appBar: AppBar(title: const Text("Error")),
                                        body: const Center(child: Text("Recipe ID is invalid.")),
                                      );
                                    }
                                    final recipeId = int.tryParse(_recipe!.id);
                                    if (recipeId == null) {
                                      return Scaffold(
                                        appBar: AppBar(title: const Text("Error")),
                                        body: const Center(child: Text("Recipe ID is not a valid number.")),
                                      );
                                    }
                                    return DiscussionScreen(
                                      comments: _comments,
                                      recipeId: recipeId, // Pass the recipeId
                                      onCommentsUpdated: (updatedComments) {
                                        if(mounted) { // Guard setState
                                          setState(() {
                                            _comments = updatedComments;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                          },
                          child: const Text("lihat semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._comments
                        .take(3) // Still taking 3 top-level comments for the main screen preview
                        .map(
                          (comment) => CommentItem(
                            key: ValueKey(comment.id), // Add key for proper updates
                            comment: comment,
                            onLike: _handleCommentLike, // Pass the method reference
                            onReply: _initiateReply,   // Pass the method reference
                          ),
                        ),
                    const SizedBox(height: 16),

                    // UI indication for replying
                    if (_replyingToCommentId != null && _replyingToUserName != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Replying to @$_replyingToUserName",
                                style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                              onPressed: () {
                                setState(() {
                                  _replyingToCommentId = null;
                                  _replyingToUserName = null;
                                });
                              },
                            )
                          ],
                        ),
                      ),

                    // Comment input
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              enabled: currentUser != null, // Disable if no user
                              decoration: InputDecoration(
                                hintText: currentUser != null ? "Diskusi di sini" : "Login to comment",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: currentUser != null ? () { // Only allow tap if user exists
                              _addComment(_commentController.text);
                            } : null,
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.subheading),
        if (subtitle != null) Text(subtitle, style: AppTextStyles.caption),
      ],
    );
  }

  void _showBookmarkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BookmarkModal(
            onSave: (folderId) async {
              try {
                await _bookmarkService.addBookmarkToFolder(
                  recipeId: widget.recipeId,
                  folderId: int.parse(folderId),
                );
                if (!mounted) return; // Guard after await
                setState(() {
                  isBookmarked = true;
                });
                Navigator.pop(context); // Pop before showing SnackBar
                if (mounted) { // Check mounted again before SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recipe bookmarked successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error bookmarking recipe: $e');
                }
                if (mounted) Navigator.pop(context); // Pop before showing SnackBar
                if (mounted) { // Check mounted again before SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error bookmarking recipe: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Widget _buildTagsSection(String title, List<String> tags) {
    if (tags.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no tags
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: tags.map((tag) => Chip(
              label: Text(tag),
              backgroundColor: Colors.teal[50],
              labelStyle: TextStyle(color: Colors.teal[800], fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            )).toList(),
          ),
          const SizedBox(height: 8), // Add some space after the tags section
        ],
      ),
    );
  }
}
