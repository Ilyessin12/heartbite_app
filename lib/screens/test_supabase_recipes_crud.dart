import 'package:flutter/material.dart';
import '../services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestSupabaseScreen extends StatefulWidget {
  const TestSupabaseScreen({Key? key}) : super(key: key);

  @override
  State<TestSupabaseScreen> createState() => _TestSupabaseScreenState();
}

class _TestSupabaseScreenState extends State<TestSupabaseScreen> {
  final _supabase = SupabaseClientWrapper().client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = false;
  String _statusMessage = '';

  // --- User Controllers ---
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  final _updateFullNameController = TextEditingController();
  final _updateUsernameController = TextEditingController();
  final _updateEmailController = TextEditingController();
  final _updatePhoneController = TextEditingController();
  final _updateBioController = TextEditingController();

  // --- Recipe Controllers ---
  final _recipeTitleController = TextEditingController();
  final _recipeDescriptionController = TextEditingController();
  final _recipeCookingTimeController = TextEditingController();
  final _recipeServingsController = TextEditingController();
  final _recipeCaloriesController = TextEditingController();
  final _recipeDifficultyController = TextEditingController(text: 'medium');
  final _recipeImageUrlController = TextEditingController();
  final _recipeGalleryUrlsController = TextEditingController();

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
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading data...';
    });
    await _fetchUsers(setLoading: false);
    await _fetchRecipes(setLoading: false);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Loaded ${_users.length} users and ${_recipes.length} recipes.';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _updateFullNameController.dispose();
    _updateUsernameController.dispose();
    _updateEmailController.dispose();
    _updatePhoneController.dispose();
    _updateBioController.dispose();

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

  Future<void> _fetchUsers({bool setLoading = true}) async {
    if (setLoading && mounted) {
      setState(() { _isLoading = true; _statusMessage = 'Loading users...'; });
    }
    try {
      final response = await _supabase.from('users').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          if (setLoading) _statusMessage = 'Loaded ${_users.length} users';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error loading users: $e'; });
      print('Error fetching users: $e');
    } finally {
      if (setLoading && mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> createUser() async {
    if (_fullNameController.text.isEmpty || _usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) setState(() { _statusMessage = 'Please fill all required user fields'; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Creating user...'; });
    try {
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: { 'username': _usernameController.text, 'full_name': _fullNameController.text, },
      );
      if (authResponse.user != null) {
        await _supabase.from('users').insert({
          'id': authResponse.user!.id,
          'full_name': _fullNameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'password_hash': 'managed_by_supabase_auth',
          'bio': _bioController.text.isEmpty ? null : _bioController.text,
          'is_active': true,
        });
        if (mounted) setState(() { _statusMessage = 'User created successfully'; });
        _fullNameController.clear(); _usernameController.clear(); _emailController.clear(); _phoneController.clear(); _passwordController.clear(); _bioController.clear();
        await _fetchUsers(setLoading: false);
      } else {
         if (mounted) setState(() { _statusMessage = 'User sign up failed.'; });
      }
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error creating user: $e'; });
      print('Error creating user: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> updateUser(String userId) async {
    if (_updateFullNameController.text.isEmpty) {
      if (mounted) setState(() { _statusMessage = 'Full name is required for user update'; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Updating user...'; });
    try {
      await _supabase.from('users').update({
        'full_name': _updateFullNameController.text,
        'username': _updateUsernameController.text,
        'email': _updateEmailController.text,
        'phone': _updatePhoneController.text,
        'bio': _updateBioController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      if (mounted) setState(() { _statusMessage = 'User updated successfully'; });
      _updateFullNameController.clear(); _updateUsernameController.clear(); _updateEmailController.clear(); _updatePhoneController.clear(); _updateBioController.clear();
      await _fetchUsers(setLoading: false);
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error updating user: $e'; });
      print('Error updating user: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> deleteUser(String userId) async {
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Deleting user...'; });
    try {
      await _supabase.from('users').delete().eq('id', userId);
      if (mounted) setState(() { _statusMessage = 'User deleted successfully'; });
      await _fetchUsers(setLoading: false);
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error deleting user: $e'; });
      print('Error deleting user: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showUpdateUserDialog(Map<String, dynamic> user) {
    _updateFullNameController.text = user['full_name'] ?? '';
    _updateUsernameController.text = user['username'] ?? '';
    _updateEmailController.text = user['email'] ?? '';
    _updatePhoneController.text = user['phone'] ?? '';
    _updateBioController.text = user['bio'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update User'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _updateFullNameController, decoration: const InputDecoration(labelText: 'Full Name*')),
            TextField(controller: _updateUsernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _updateEmailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _updatePhoneController, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: _updateBioController, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.of(context).pop(); updateUser(user['id'] as String); }, child: const Text('Update')),
        ],
      ),
    );
  }

  Future<void> _fetchRecipes({bool setLoading = true}) async {
    if (setLoading && mounted) {
      setState(() { _isLoading = true; _statusMessage = 'Loading recipes...'; });
    }
    try {
      final response = await _supabase.from('recipes').select('*, users(username), recipe_gallery_images(image_url)').order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _recipes = List<Map<String, dynamic>>.from(response);
           if (setLoading) _statusMessage = 'Loaded ${_recipes.length} recipes';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error loading recipes: $e'; });
      print('Error fetching recipes: $e');
    } finally {
      if (setLoading && mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _createRecipe() async {
    if (_recipeTitleController.text.isEmpty || _recipeCookingTimeController.text.isEmpty || _recipeServingsController.text.isEmpty) {
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
        'cooking_time_minutes': int.parse(_recipeCookingTimeController.text),
        'servings': int.parse(_recipeServingsController.text),
        'calories': _recipeCaloriesController.text.isEmpty ? null : int.parse(_recipeCaloriesController.text),
        'difficulty_level': _recipeDifficultyController.text,
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
      _recipeTitleController.clear(); _recipeDescriptionController.clear(); _recipeCookingTimeController.clear();
      _recipeServingsController.clear(); _recipeCaloriesController.clear(); _recipeDifficultyController.text = 'medium';
      _recipeImageUrlController.clear(); _recipeGalleryUrlsController.clear();
      if (mounted) setState(() { _statusMessage = 'Recipe created successfully'; });
      await _fetchRecipes(setLoading: false);
    } catch (e) {
      if (mounted) setState(() { _statusMessage = 'Error creating recipe: $e'; });
      print('Error creating recipe: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateRecipe(int recipeId) async {
     if (_updateRecipeTitleController.text.isEmpty || _updateRecipeCookingTimeController.text.isEmpty || _updateRecipeServingsController.text.isEmpty) {
      if (mounted) setState(() { _statusMessage = 'Recipe title, cooking time, and servings are required for update.'; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; _statusMessage = 'Updating recipe...'; });
    try {
      await _supabase.from('recipes').update({
        'title': _updateRecipeTitleController.text,
        'description': _updateRecipeDescriptionController.text.isEmpty ? null : _updateRecipeDescriptionController.text,
        'cooking_time_minutes': int.parse(_updateRecipeCookingTimeController.text),
        'servings': int.parse(_updateRecipeServingsController.text),
        'calories': _updateRecipeCaloriesController.text.isEmpty ? null : int.parse(_updateRecipeCaloriesController.text),
        'difficulty_level': _updateRecipeDifficultyController.text,
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
      _updateRecipeTitleController.clear(); _updateRecipeDescriptionController.clear(); _updateRecipeCookingTimeController.clear();
      _updateRecipeServingsController.clear(); _updateRecipeCaloriesController.clear(); _updateRecipeDifficultyController.clear();
      _updateRecipeImageUrlController.clear(); _updateRecipeGalleryUrlsController.clear();
      await _fetchRecipes(setLoading: false);
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
      await _fetchRecipes(setLoading: false);
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
        title: const Text('Supabase Test CRUD'),
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAllData) ],
      ),
      body: _isLoading && (_users.isEmpty && _recipes.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_statusMessage, style: TextStyle(color: _statusMessage.startsWith('Error') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  ExpansionTile(
                    title: const Text('User CRUD'),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(children: [
                          TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name*')),
                          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username*')),
                          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email*'), keyboardType: TextInputType.emailAddress),
                          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password*'), obscureText: true),
                          TextField(controller: _bioController, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 3),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: createUser, child: const Text('Create User')),
                        ]),
                      ),
                      ExpansionTile(
                        title: Text('User List (${_users.length})'),
                        initiallyExpanded: false,
                        children: [
                          ListView.builder(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: ListTile(
                                  title: Text('${user['full_name']}'),
                                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('@${user['username']}'), Text('${user['email']}'),
                                    if (user['bio'] != null && user['bio'].isNotEmpty) Text('${user['bio']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ]),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showUpdateUserDialog(user)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                                      showDialog(context: context, builder: (context) => AlertDialog(
                                        title: const Text('Delete User'),
                                        content: Text('Are you sure you want to delete ${user['full_name']}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                          TextButton(onPressed: () { Navigator.of(context).pop(); deleteUser(user['id'] as String); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
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
                  const Divider(),
                  ExpansionTile(
                    title: const Text('Recipe CRUD'),
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
                ],
              ),
            ),
          ),
    );
  }
}
