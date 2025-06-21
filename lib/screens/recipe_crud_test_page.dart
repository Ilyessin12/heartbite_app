import 'package:flutter/material.dart';
import '../services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeCrudTestPage extends StatefulWidget {
  const RecipeCrudTestPage({Key? key}) : super(key: key);

  @override
  State<RecipeCrudTestPage> createState() => _RecipeCrudTestPageState();
}

class _RecipeCrudTestPageState extends State<RecipeCrudTestPage> {
  final _supabase = SupabaseClientWrapper().client;
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = false;
  String _statusMessage = '';

  // --- Recipe Controllers ---
  final _recipeTitleController = TextEditingController();
  final _recipeDescriptionController = TextEditingController();
  final _recipeCookingTimeController = TextEditingController();
  final _recipeServingsController = TextEditingController();
  final _recipeCaloriesController = TextEditingController();
  final _recipeDifficultyController = TextEditingController(text: 'medium');
  final _recipeImageUrlController = TextEditingController();
  final _recipeGalleryUrlsController = TextEditingController(); // Comma-separated

  // Controllers for update recipe form
  final _updateRecipeTitleController = TextEditingController();
  final _updateRecipeDescriptionController = TextEditingController();
  final _updateRecipeCookingTimeController = TextEditingController();
  final _updateRecipeServingsController = TextEditingController();
  final _updateRecipeCaloriesController = TextEditingController();
  final _updateRecipeDifficultyController = TextEditingController();
  final _updateRecipeImageUrlController = TextEditingController();
  final _updateRecipeGalleryUrlsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  @override
  void dispose() {
    _recipeTitleController.dispose();
    _recipeDescriptionController.dispose();
    _recipeCookingTimeController.dispose();
    _recipeServingsController.dispose();
    _recipeCaloriesController.dispose();
    _recipeDifficultyController.dispose();
    _recipeImageUrlController.dispose();
    _recipeGalleryUrlsController.dispose();
    _updateRecipeTitleController.dispose();
    _updateRecipeDescriptionController.dispose();
    _updateRecipeCookingTimeController.dispose();
    _updateRecipeServingsController.dispose();
    _updateRecipeCaloriesController.dispose();
    _updateRecipeDifficultyController.dispose();
    _updateRecipeImageUrlController.dispose();
    _updateRecipeGalleryUrlsController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecipes() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _statusMessage = 'Loading recipes...'; });
    try {
      final response = await _supabase
          .from('recipes')
          .select('*, users(username), recipe_gallery_images(image_url)') // Join with users and gallery
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _recipes = List<Map<String, dynamic>>.from(response);
        _statusMessage = 'Loaded ${_recipes.length} recipes';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _statusMessage = 'Error loading recipes: $e'; });
      print('Error fetching recipes: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _createRecipe() async {
    if (_recipeTitleController.text.isEmpty ||
        _recipeCookingTimeController.text.isEmpty ||
        _recipeServingsController.text.isEmpty) {
      if (mounted) setState(() { _statusMessage = 'Recipe title, cooking time, and servings are required.'; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Creating recipe...'; });

    try {
      const String hardcodedUserId = '325c40cc-d255-4f93-bf5f-40bc196ca093';

      final List<Map<String,dynamic>> insertedRecipe = await _supabase.from('recipes').insert({
        'user_id': hardcodedUserId,
        'title': _recipeTitleController.text,
        'description': _recipeDescriptionController.text.isEmpty ? null : _recipeDescriptionController.text,
        'cooking_time_minutes': int.tryParse(_recipeCookingTimeController.text) ?? 0,
        'servings': int.tryParse(_recipeServingsController.text) ?? 1,
        'calories': _recipeCaloriesController.text.isEmpty ? null : int.tryParse(_recipeCaloriesController.text),
        'difficulty_level': _recipeDifficultyController.text.isEmpty ? 'medium' : _recipeDifficultyController.text,
        'image_url': _recipeImageUrlController.text.isEmpty ? null : _recipeImageUrlController.text,
        'is_published': true,
      }).select();

      if (insertedRecipe.isNotEmpty) {
        final newRecipeId = insertedRecipe.first['id'];
        if (_recipeGalleryUrlsController.text.isNotEmpty) {
          final urls = _recipeGalleryUrlsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (urls.isNotEmpty) {
            final galleryImagesData = urls.asMap().entries.map((entry) => {
              'recipe_id': newRecipeId, 'image_url': entry.value, 'order_index': entry.key,
            }).toList();
            await _supabase.from('recipe_gallery_images').insert(galleryImagesData);
          }
        }
      }

      _recipeTitleController.clear();
      _recipeDescriptionController.clear();
      _recipeCookingTimeController.clear();
      _recipeServingsController.clear();
      _recipeCaloriesController.clear();
      _recipeDifficultyController.text = 'medium';
      _recipeImageUrlController.clear();
      _recipeGalleryUrlsController.clear();

      if (mounted) setState(() { _statusMessage = 'Recipe created successfully'; });
      await _fetchRecipes();
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error creating recipe: $e'; });
      print('Error creating recipe: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateRecipe(int recipeId) async {
     if (_updateRecipeTitleController.text.isEmpty ||
        _updateRecipeCookingTimeController.text.isEmpty ||
        _updateRecipeServingsController.text.isEmpty) {
      if (mounted) setState(() { _statusMessage = 'Recipe title, cooking time, and servings are required for update.';});
      return;
    }
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Updating recipe...'; });
    try {
      await _supabase.from('recipes').update({
        'title': _updateRecipeTitleController.text,
        'description': _updateRecipeDescriptionController.text.isEmpty ? null : _updateRecipeDescriptionController.text,
        'cooking_time_minutes': int.tryParse(_updateRecipeCookingTimeController.text) ?? 0,
        'servings': int.tryParse(_updateRecipeServingsController.text) ?? 1,
        'calories': _updateRecipeCaloriesController.text.isEmpty ? null : int.tryParse(_updateRecipeCaloriesController.text),
        'difficulty_level': _updateRecipeDifficultyController.text.isEmpty ? 'medium' : _updateRecipeDifficultyController.text,
        'image_url': _updateRecipeImageUrlController.text.isEmpty ? null : _updateRecipeImageUrlController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', recipeId);

      await _supabase.from('recipe_gallery_images').delete().eq('recipe_id', recipeId);
      if (_updateRecipeGalleryUrlsController.text.isNotEmpty) {
          final urls = _updateRecipeGalleryUrlsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (urls.isNotEmpty) {
            final galleryImagesData = urls.asMap().entries.map((entry) => {
              'recipe_id': recipeId, 'image_url': entry.value, 'order_index': entry.key,
            }).toList();
            await _supabase.from('recipe_gallery_images').insert(galleryImagesData);
          }
        }
      if (mounted) setState(() { _statusMessage = 'Recipe updated successfully'; });
      _updateRecipeTitleController.clear();_updateRecipeDescriptionController.clear();_updateRecipeCookingTimeController.clear();
      _updateRecipeServingsController.clear();_updateRecipeCaloriesController.clear();_updateRecipeDifficultyController.clear();
      _updateRecipeImageUrlController.clear();_updateRecipeGalleryUrlsController.clear();
      await _fetchRecipes();
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error updating recipe: $e'; });
      print('Error updating recipe: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteRecipe(int recipeId) async {
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Deleting recipe...'; });
    try {
      await _supabase.from('recipes').delete().eq('id', recipeId);
      if (mounted) setState(() { _statusMessage = 'Recipe deleted successfully'; });
      await _fetchRecipes();
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error deleting recipe: $e'; });
      print('Error deleting recipe: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showUpdateRecipeDialog(Map<String, dynamic> recipe) {
    _updateRecipeTitleController.text = recipe['title'] ?? '';
    _updateRecipeDescriptionController.text = recipe['description'] ?? '';
    _updateRecipeCookingTimeController.text = recipe['cooking_time_minutes']?.toString() ?? '';
    _updateRecipeServingsController.text = recipe['servings']?.toString() ?? '';
    _updateRecipeCaloriesController.text = recipe['calories']?.toString() ?? '';
    _updateRecipeDifficultyController.text = recipe['difficulty_level'] ?? 'medium';
    _updateRecipeImageUrlController.text = recipe['image_url'] ?? '';

    final galleryImages = recipe['recipe_gallery_images'] as List<dynamic>?;
    _updateRecipeGalleryUrlsController.text = galleryImages
        ?.map((img) => (img as Map<String,dynamic>)['image_url'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .join(', ') ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Recipe'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _updateRecipeTitleController, decoration: const InputDecoration(labelText: 'Title*')),
            TextField(controller: _updateRecipeDescriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            TextField(controller: _updateRecipeCookingTimeController, decoration: const InputDecoration(labelText: 'Cooking Time (min)*'), keyboardType: TextInputType.number),
            TextField(controller: _updateRecipeServingsController, decoration: const InputDecoration(labelText: 'Servings*'), keyboardType: TextInputType.number),
            TextField(controller: _updateRecipeCaloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
            TextField(controller: _updateRecipeDifficultyController, decoration: const InputDecoration(labelText: 'Difficulty (easy, medium, hard)')),
            TextField(controller: _updateRecipeImageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(controller: _updateRecipeGalleryUrlsController, decoration: const InputDecoration(labelText: 'Gallery URLs (comma-sep)'), maxLines:2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.of(context).pop(); _updateRecipe(recipe['id'] as int); }, child: const Text('Update Recipe')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe CRUD Test Page'),
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRecipes) ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecipes,
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_statusMessage, style: TextStyle(color: _statusMessage.startsWith('Error') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  ExpansionTile(
                    title: const Text('Create New Recipe'),
                    initiallyExpanded: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(children: [
                          TextField(controller: _recipeTitleController, decoration: const InputDecoration(labelText: 'Title*')),
                          TextField(controller: _recipeDescriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                          TextField(controller: _recipeCookingTimeController, decoration: const InputDecoration(labelText: 'Cooking Time (min)*'), keyboardType: TextInputType.number),
                          TextField(controller: _recipeServingsController, decoration: const InputDecoration(labelText: 'Servings*'), keyboardType: TextInputType.number),
                          TextField(controller: _recipeCaloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
                          TextField(controller: _recipeDifficultyController, decoration: const InputDecoration(labelText: 'Difficulty (easy, medium, hard)')),
                          TextField(controller: _recipeImageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
                          TextField(controller: _recipeGalleryUrlsController, decoration: const InputDecoration(labelText: 'Gallery URLs (comma-sep)'), maxLines: 2),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _createRecipe, child: const Text('Create Recipe')),
                        ]),
                      ),
                    ],
                  ),
                  const Divider(),
                  ExpansionTile(
                    title: Text('Recipe List (${_recipes.length})'),
                    initiallyExpanded: true,
                    children: [
                      ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          final author = recipe['users'] != null ? recipe['users']['username'] : 'Unknown';
                          final galleryImages = recipe['recipe_gallery_images'] as List<dynamic>?;
                          String galleryText = galleryImages != null && galleryImages.isNotEmpty
                            ? "Gallery: ${galleryImages.length} image(s)"
                            : "Gallery: N/A";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              leading: recipe['image_url'] != null && (recipe['image_url'] as String).isNotEmpty
                                ? Image.network(recipe['image_url'] as String, width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50))
                                : const Icon(Icons.image_not_supported, size: 50),
                              title: Text(recipe['title'] ?? 'No Title'),
                              subtitle: Text('By: $author\nDifficulty: ${recipe['difficulty_level']} - ${recipe['cooking_time_minutes']} min\n$galleryText'),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _showUpdateRecipeDialog(recipe)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                                  showDialog(context: context, builder: (context) => AlertDialog(
                                    title: const Text('Delete Recipe'),
                                    content: Text('Are you sure you want to delete "${recipe['title']}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                      TextButton(onPressed: () { Navigator.of(context).pop(); _deleteRecipe(recipe['id'] as int); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ));
                                }),
                              ]),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
