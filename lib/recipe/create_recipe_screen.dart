import 'dart:io'; // Added for File type
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Models no longer used, data will be mapped directly for database schema

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for TextFormFields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController(); // New
  File? _selectedImageFile; // Added for image picking
  List<File> _selectedGalleryImageFiles = []; // Added for gallery images

  final _caloriesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1'); 
  final _cookingMinutesController = TextEditingController();
  final _difficultyLevelController = TextEditingController(text: 'medium'); 
  final _ingredientsController = TextEditingController();
  final _directionsController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers
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

  void _saveRecipe() async { // Made async for Future.delayed
    if (_formKey.currentState!.validate()) {
      String? imageUrlForDb;
      if (_selectedImageFile != null) {
        print("Simulating image upload for: ${_selectedImageFile!.path}");
        imageUrlForDb = "https://res.cloudinary.com/demo/image/upload/sample_from_create.jpg"; // Dummy URL
      }

      List<String> galleryImageUrls = [];
      if (_selectedGalleryImageFiles.isNotEmpty) {
        print("Simulating upload for gallery images...");
        for (File imageFile in _selectedGalleryImageFiles) {
          await Future.delayed(const Duration(milliseconds: 100)); // Simulate individual upload
          galleryImageUrls.add("https://res.cloudinary.com/demo/image/upload/gallery_sample_${galleryImageUrls.length + 1}.jpg");
        }
        print("Gallery images 'uploaded'. URLs: $galleryImageUrls");
      }

      final Map<String, dynamic> recipeData = {
        'user_id': 1, // Placeholder user_id
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'image_url': imageUrlForDb ?? '', 
        'calories': int.tryParse(_caloriesController.text), 
        'servings': int.tryParse(_servingsController.text) ?? 1, 
        'cooking_time_minutes': int.tryParse(_cookingMinutesController.text), 
        'difficulty_level': _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
        'like_count': 0, 
        'ingredients_text': _ingredientsController.text,
        'directions_text': _directionsController.text,
        'gallery_image_urls': galleryImageUrls, // Use the new key and list
        // 'is_published' will use database default
      };

      print('Recipe Data Map:');
      print(recipeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe data map printed to console.')),
      );
    }
  }

  Future<void> _pickImage() async {
    print("Pick image button pressed. Implement image_picker functionality here.");
    setState(() {
      if (_selectedImageFile == null) {
        print("Simulating main image selection for UI test purposes - no actual file will be set for preview.");
      }
    });
  }

  Future<void> _pickGalleryImages() async {
    print("Pick gallery images button pressed. Implement multi-image_picker functionality here.");
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.dmSans(fontSize: 16);
    final labelStyle = GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[700]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Recipe (DB Schema)', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
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
                  onPressed: _pickImage,
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
                        onPressed: _pickGalleryImages,
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
                ElevatedButton(
                  key: const Key('save_button'),
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
