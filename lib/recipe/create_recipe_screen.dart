import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../services/image_upload_service.dart';
import '../services/recipe_service.dart'; // Import RecipeService
import '../models/recipe_model.dart'; // Import RecipeModel
import '../services/supabase_client.dart'; // Import SupabaseClientWrapper for user ID

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImageFile;
  List<File> _selectedGalleryImageFiles = [];

  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final RecipeService _recipeService = RecipeService(); // Instantiate RecipeService
  bool _isUploadingOrSaving = false;

  final _caloriesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _cookingMinutesController = TextEditingController();
  final _difficultyLevelController = TextEditingController(text: 'medium');

  // Controllers for ingredients and directions - data will be passed to RecipeModel
  // but not directly saved to 'recipes' table columns by RecipeService.createRecipe
  // This can be used later if we decide to parse and save them to related tables.
  final _ingredientsController = TextEditingController();
  final _directionsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();
    _cookingMinutesController.dispose();
    _difficultyLevelController.dispose();
    _ingredientsController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // final currentUser = SupabaseClientWrapper().auth.currentUser; // Commented out user check
    // if (currentUser == null) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('You must be logged in to create a recipe.')),
    //     );
    //   }
    //   return;
    // }

    if (_isUploadingOrSaving) return;

    setState(() {
      _isUploadingOrSaving = true;
    });

    String? mainImageUrl;
    if (_selectedImageFile != null) {
      mainImageUrl = await _imageUploadService.uploadImage(_selectedImageFile!);
      if (mainImageUrl == null) {
        setState(() { _isUploadingOrSaving = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Main recipe image upload failed. Please try again.')),
          );
        }
        return;
      }
    }

    List<String> galleryImageUrls = [];
    if (_selectedGalleryImageFiles.isNotEmpty) {
      for (File imageFile in _selectedGalleryImageFiles) {
        String? url = await _imageUploadService.uploadImage(imageFile);
        if (url != null) {
          galleryImageUrls.add(url);
        } else {
          print('A gallery image failed to upload and will be skipped.');
          // Optionally, inform the user about skipped images
        }
      }
    }

    const String hardcodedUserId = '325c40cc-d255-4f93-bf5f-40bc196ca093';

    RecipeModel recipeToCreate = RecipeModel(
      user_id: hardcodedUserId, // Use hardcoded user_id
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      image_url: mainImageUrl,
      calories: int.tryParse(_caloriesController.text),
      servings: int.tryParse(_servingsController.text) ?? 1,
      cooking_time_minutes: int.parse(_cookingMinutesController.text),
      difficulty_level: _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
      is_published: true,
      ingredients_text: _ingredientsController.text.isEmpty ? null : _ingredientsController.text,
      directions_text: _directionsController.text.isEmpty ? null : _directionsController.text,
    );

    try {
      await _recipeService.createRecipe(recipeToCreate, galleryImageUrls);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe created successfully!')),
        );
        Navigator.pop(context, true); // Pop and indicate success
      }
    } catch (e) {
      print('Error saving recipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create recipe: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingOrSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isUploadingOrSaving) return; // Use the corrected variable name
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    if (_isUploadingOrSaving) return;
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedGalleryImageFiles.addAll(pickedFiles.map((xf) => File(xf.path)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.dmSans(fontSize: 16);
    final labelStyle = GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[700]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Recipe', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const Key('title_field'),
                  controller: _titleController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Title*', labelStyle: labelStyle),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField( 
                  key: const Key('description_field'),
                  controller: _descriptionController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Description', labelStyle: labelStyle),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                // Main Image Picker UI
                if (_selectedImageFile != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      image: DecorationImage(
                        image: FileImage(_selectedImageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  key: const Key('pick_image_button'), 
                  onPressed: _isUploading ? null : _pickImage, // Disable if uploading
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Recipe Image'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('calories_field'),
                  controller: _caloriesController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Calories (e.g., 250)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField( 
                  key: const Key('servings_field'),
                  controller: _servingsController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Servings* (e.g., 4)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of servings';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid number of servings';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField( 
                  key: const Key('cooking_minutes_field'),
                  controller: _cookingMinutesController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Cooking Minutes* (e.g., 30)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cooking minutes';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter valid cooking minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField( 
                  key: const Key('difficulty_level_field'),
                  controller: _difficultyLevelController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Difficulty Level (e.g., easy, medium, hard)', labelStyle: labelStyle),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('ingredients_field'),
                  controller: _ingredientsController,
                  style: textStyle,
                  decoration: InputDecoration(
                    labelText: 'Ingredients (one per line)',
                    labelStyle: labelStyle,
                    hintText: '1 cup flour\n2 eggs\n...',
                  ),
                  maxLines: null, 
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ingredients';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('directions_field'),
                  controller: _directionsController,
                  style: textStyle,
                  decoration: InputDecoration(
                    labelText: 'Directions (one step per line)',
                    labelStyle: labelStyle,
                    hintText: 'Mix flour and eggs.\nBake at 350°F for 30 minutes.\n...',
                  ),
                  maxLines: null, 
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter directions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Gallery Image Picker UI
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Gallery Images", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        key: const Key('pick_gallery_images_button'), 
                        onPressed: _isUploading ? null : _pickGalleryImages, // Disable if uploading
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add Gallery Images'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedGalleryImageFiles.isNotEmpty)
                        Container(
                          height: 100, 
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedGalleryImageFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        image: DecorationImage(
                                          image: FileImage(_selectedGalleryImageFiles[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _selectedGalleryImageFiles.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      key: const Key('save_button'), // Corrected key name
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _saveRecipe,
                      child: const Text('Save Recipe Data'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
