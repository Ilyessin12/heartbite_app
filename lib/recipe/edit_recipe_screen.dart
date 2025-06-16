import 'dart:io'; // Added for File type
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditRecipeScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const EditRecipeScreen({super.key, required this.recipeData});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for TextFormFields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _newSelectedImageFile; // For new main image
  String? _existingImageUrl; // For existing main image

  late TextEditingController _caloriesController;
  late TextEditingController _servingsController;
  late TextEditingController _cookingMinutesController;
  late TextEditingController _difficultyLevelController;
  late TextEditingController _ingredientsController;
  late TextEditingController _directionsController;

  List<String> _galleryImageUrls = []; // For existing gallery URLs
  List<File> _newSelectedGalleryImageFiles = []; // For new gallery files

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from the recipeData map
    _titleController = TextEditingController(text: widget.recipeData['title']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.recipeData['description']?.toString() ?? '');
    _existingImageUrl = widget.recipeData['image_url'] as String?;
    _caloriesController = TextEditingController(text: widget.recipeData['calories']?.toString() ?? '');
    _servingsController = TextEditingController(text: widget.recipeData['servings']?.toString() ?? '1');
    _cookingMinutesController = TextEditingController(text: widget.recipeData['cooking_time_minutes']?.toString() ?? '');
    _difficultyLevelController = TextEditingController(text: widget.recipeData['difficulty_level']?.toString() ?? 'medium');
    _ingredientsController = TextEditingController(text: widget.recipeData['ingredients_text']?.toString() ?? '');
    _directionsController = TextEditingController(text: widget.recipeData['directions_text']?.toString() ?? '');

    // Initialize _galleryImageUrls from widget.recipeData
    var galleryData = widget.recipeData['gallery_image_urls'];
    if (galleryData is List) {
      _galleryImageUrls = List<String>.from(galleryData.whereType<String>());
    } else if (galleryData is String && galleryData.isNotEmpty) {
      // Fallback for old data that might be a single string or newline separated (less robust)
      // This part might need adjustment based on actual old data format.
      // For now, if it's a string, split by newline, otherwise treat as single.
      if (galleryData.contains('\n')) {
         _galleryImageUrls = galleryData.split('\n').where((url) => url.trim().isNotEmpty).toList();
      } else {
        _galleryImageUrls = [galleryData];
      }
    }
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

  void _saveChanges() async { // Made async
    if (_formKey.currentState!.validate()) {
      String? finalImageUrl = _existingImageUrl; 

      if (_newSelectedImageFile != null) {
        print("Simulating new main image upload for: ${_newSelectedImageFile!.path}");
        finalImageUrl = "https://res.cloudinary.com/demo/image/upload/sample_from_edit_main.jpg"; 
      }

      List<String> finalGalleryImageUrls = List.from(_galleryImageUrls); 

      if (_newSelectedGalleryImageFiles.isNotEmpty) {
        print("Simulating upload for new gallery images on Edit screen...");
        for (File imageFile in _newSelectedGalleryImageFiles) {
          await Future.delayed(const Duration(milliseconds: 100)); // Simulate upload
          finalGalleryImageUrls.add("https://res.cloudinary.com/demo/image/upload/new_gallery_sample_${finalGalleryImageUrls.length + 1}.jpg");
        }
        print("New gallery images 'uploaded'.");
      }

      final Map<String, dynamic> updatedRecipeData = {
        'id': widget.recipeData['id'], 
        'user_id': widget.recipeData['user_id'], 
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'image_url': finalImageUrl ?? '', 
        'calories': int.tryParse(_caloriesController.text),
        'servings': int.tryParse(_servingsController.text) ?? 1,
        'cooking_time_minutes': int.tryParse(_cookingMinutesController.text),
        'difficulty_level': _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
        'like_count': widget.recipeData['like_count'] ?? 0, 
        'ingredients_text': _ingredientsController.text,
        'directions_text': _directionsController.text,
        'gallery_image_urls': finalGalleryImageUrls, 
      };

      print('Updated Recipe Data Map:');
      print(updatedRecipeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated recipe data map printed to console.')),
      );
    }
  }

  Future<void> _pickImage() async {
    print("Pick main image button pressed on Edit Screen. Implement image_picker functionality here.");
    setState(() {}); 
  }

  Future<void> _pickGalleryImages() async {
    print("Pick gallery images button pressed on Edit Screen. Implement multi-image_picker functionality here.");
    setState(() {});
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
                // Main Image display and picker UI
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
                        onPressed: _pickImage,
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
                        key: const Key('pick_gallery_images_button_edit'), 
                        onPressed: _pickGalleryImages, 
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add More Gallery Images'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      if (_galleryImageUrls.isNotEmpty || _newSelectedGalleryImageFiles.isNotEmpty)
                        Container(
                          height: 120, 
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _galleryImageUrls.length + _newSelectedGalleryImageFiles.length,
                            itemBuilder: (context, index) {
                              Widget imageWidget;
                              bool isNewFile = index >= _galleryImageUrls.length;
                              
                              if (isNewFile) {
                                imageWidget = Image.file(_newSelectedGalleryImageFiles[index - _galleryImageUrls.length], fit: BoxFit.cover);
                              } else {
                                imageWidget = Image.network(_galleryImageUrls[index], fit: BoxFit.cover,
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
                                              _newSelectedGalleryImageFiles.removeAt(index - _galleryImageUrls.length);
                                            } else {
                                              _galleryImageUrls.removeAt(index);
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
                ElevatedButton(
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
