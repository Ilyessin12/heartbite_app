import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Tidak digunakan secara langsung di sini
import '../services/image_upload_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';
import '../services/supabase_client.dart'; // Untuk SupabaseClientWrapper().auth.currentUser

class EditRecipeScreen extends StatefulWidget {
  final RecipeModel recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  File? _newSelectedImageFile; 
  String? _existingImageUrl; 

  final ImagePicker _picker = ImagePicker(); 
  final ImageUploadService _imageUploadService = ImageUploadService(); 
  final RecipeService _recipeService = RecipeService();
  bool _isUploadingOrSaving = false; // Nama variabel yang benar

  late TextEditingController _caloriesController;
  late TextEditingController _servingsController;
  late TextEditingController _cookingMinutesController;
  late TextEditingController _difficultyLevelController;
  late TextEditingController _ingredientsController;
  late TextEditingController _directionsController;

  List<String> _existingGalleryImageUrls = [];
  List<File> _newSelectedGalleryImageFiles = []; 

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description ?? '');
    _existingImageUrl = widget.recipe.image_url;
    _caloriesController = TextEditingController(text: widget.recipe.calories?.toString() ?? '');
    _servingsController = TextEditingController(text: widget.recipe.servings.toString());
    _cookingMinutesController = TextEditingController(text: widget.recipe.cooking_time_minutes.toString());
    _difficultyLevelController = TextEditingController(text: widget.recipe.difficulty_level);
    _ingredientsController = TextEditingController(text: widget.recipe.ingredients_text ?? '');
    _directionsController = TextEditingController(text: widget.recipe.directions_text ?? '');
    _existingGalleryImageUrls = List<String>.from(widget.recipe.gallery_image_urls ?? []);
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final currentUser = SupabaseClientWrapper().auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to edit a recipe.')),
        );
      }
      return;
    }

    if (widget.recipe.user_id != currentUser.id) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You are not authorized to edit this recipe.')),
            );
        }
        return;
    }

    if (_isUploadingOrSaving) return;

    setState(() {
      _isUploadingOrSaving = true;
    });

    String? finalMainImageUrl = _existingImageUrl;
    if (_newSelectedImageFile != null) {
      finalMainImageUrl = await _imageUploadService.uploadImage(_newSelectedImageFile!);
      if (finalMainImageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Main recipe image upload failed. Please try again.')),
          );
          setState(() { _isUploadingOrSaving = false; });
        }
        return;
      }
    }

    List<String> finalGalleryImageUrls = List.from(_existingGalleryImageUrls);

    if (_newSelectedGalleryImageFiles.isNotEmpty) {
      for (File imageFile in _newSelectedGalleryImageFiles) {
        String? url = await _imageUploadService.uploadImage(imageFile);
        if (url != null) {
          finalGalleryImageUrls.add(url);
        } else {
          print('A new gallery image failed to upload and will be skipped.');
        }
      }
    }

    RecipeModel recipeToUpdate = RecipeModel(
      id: widget.recipe.id,
      user_id: widget.recipe.user_id,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      image_url: finalMainImageUrl,
      calories: int.tryParse(_caloriesController.text),
      servings: int.parse(_servingsController.text),
      cooking_time_minutes: int.parse(_cookingMinutesController.text),
      difficulty_level: _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
      is_published: widget.recipe.is_published,
      created_at: widget.recipe.created_at,
      ingredients_text: _ingredientsController.text.isEmpty ? null : _ingredientsController.text,
      directions_text: _directionsController.text.isEmpty ? null : _directionsController.text,
    );

    try {
      await _recipeService.updateRecipe(recipeToUpdate, finalGalleryImageUrls);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating recipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update recipe: ${e.toString()}')),
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
    if (_isUploadingOrSaving) return;
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newSelectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    if (_isUploadingOrSaving) return;
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newSelectedGalleryImageFiles.addAll(pickedFiles.map((xf) => File(xf.path)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.dmSans(fontSize: 16);
    final labelStyle = GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[700]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Recipe Image", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_newSelectedImageFile != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            image: DecorationImage(image: FileImage(_newSelectedImageFile!), fit: BoxFit.cover),
                          ),
                          margin: const EdgeInsets.only(bottom: 8.0),
                        )
                      else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            image: DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover),
                          ),
                          margin: const EdgeInsets.only(bottom: 8.0),
                        )
                      else
                        Container( 
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: Center(child: Text("No image provided", style: GoogleFonts.dmSans())),
                          margin: const EdgeInsets.only(bottom: 8.0),
                        ),
                      ElevatedButton.icon(
                        key: const Key('pick_image_button_edit'), 
                        onPressed: _isUploadingOrSaving ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: Text(_existingImageUrl != null && _existingImageUrl!.isNotEmpty ? 'Change Image' : 'Pick Image'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('calories_field'),
                  controller: _caloriesController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Calories (e.g., 250)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return 'Please enter a valid number for calories';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !['easy', 'medium', 'hard'].contains(value.toLowerCase())) {
                      return 'Must be easy, medium, or hard';
                    }
                    return null;
                  },
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
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Gallery Images", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        key: const Key('pick_gallery_images_button_edit'), 
                        onPressed: _isUploadingOrSaving ? null : _pickGalleryImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add More Gallery Images'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      if (_existingGalleryImageUrls.isNotEmpty || _newSelectedGalleryImageFiles.isNotEmpty)
                        SizedBox( // Changed Container to SizedBox for height constraint
                          height: 120, 
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingGalleryImageUrls.length + _newSelectedGalleryImageFiles.length,
                            itemBuilder: (context, index) {
                              Widget imageWidget;
                              bool isNewFile = index >= _existingGalleryImageUrls.length;
                              
                              if (isNewFile) {
                                imageWidget = Image.file(_newSelectedGalleryImageFiles[(index - _existingGalleryImageUrls.length).toInt()], fit: BoxFit.cover);
                              } else {
                                imageWidget = Image.network(_existingGalleryImageUrls[index], fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                                      child: imageWidget,
                                    ),
                                    Positioned(
                                      top: -10, 
                                      right: -10,
                                      child: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            if (isNewFile) {
                                              _newSelectedGalleryImageFiles.removeAt((index - _existingGalleryImageUrls.length).toInt());
                                            } else {
                                              _existingGalleryImageUrls.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text("No gallery images yet.", style: GoogleFonts.dmSans()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _isUploadingOrSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      key: const Key('save_button'), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
