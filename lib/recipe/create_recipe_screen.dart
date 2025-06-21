import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client not directly used here for user
import '../services/image_upload_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';
// import '../services/supabase_client.dart'; // SupabaseClientWrapper for user ID - using hardcoded for now

class InstructionStepData {
  final UniqueKey id; // For list item identification if needed for animations/keys
  final TextEditingController textController;
  File? selectedImageFile;
  String? existingImageUrl; // For future edit functionality

  InstructionStepData({
    String initialText = '',
    this.selectedImageFile,
    this.existingImageUrl,
  }) : id = UniqueKey(), textController = TextEditingController(text: initialText);

  // Call this when the InstructionStepData object is no longer needed to free resources
  void dispose() {
    textController.dispose();
  }
}

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
  final RecipeService _recipeService = RecipeService();
  bool _isUploadingOrSaving = false;

  final _caloriesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _cookingMinutesController = TextEditingController();
  final _difficultyLevelController = TextEditingController(text: 'medium');

  final _ingredientsController = TextEditingController();
  // final _directionsController = TextEditingController(); // Removed
  List<InstructionStepData> _instructionSteps = [];

  @override
  void initState() {
    super.initState();
    // Start with one empty instruction step
    _instructionSteps.add(InstructionStepData());
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
    // _directionsController.dispose(); // This line is removed as _directionsController is removed.
    for (var stepData in _instructionSteps) {
      stepData.dispose();
    }
    super.dispose();
  }

  List<RecipeIngredientModel> _parseIngredients(String text) {
    final List<RecipeIngredientModel> ingredients = [];
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Regex to capture:
    // 1. (Optional) Quantity: numbers, decimals, fractions (e.g., "1", "0.5", "1/2", "1 1/2")
    // 2. (Optional) Unit: common units or any non-numeric word following quantity
    // 3. Name: the rest of the string
    // This regex is more complex to handle mixed fractions like "1 1/2"
    final RegExp regex = RegExp(
      r'^\s*(?:([\d\.\/]+(?:\s+[\d\.\/]+)?)\s+)?' // Optional quantity (group 1) with optional mixed fraction
      r'(?:(\S+)\s+)?'                             // Optional unit (group 2)
      r'(.+)$'                                      // Name (group 3)
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final match = regex.firstMatch(line);

      double quantity = 1.0;
      String? unit;
      String name = line; // Default to whole line if no parse

      if (match != null) {
        String? qtyStr = match.group(1);
        String? unitOrFirstNamePart = match.group(2); // This could be a unit or the first word of the name
        String? nameRemainderStr = match.group(3);

        if (qtyStr != null) {
          qtyStr = qtyStr.trim();
          // Parse quantity (handles "1", "0.5", "1/2", "1 1/2")
          if (qtyStr.contains(' ')) { // Mixed fraction like "1 1/2"
            final parts = qtyStr.split(' ');
            if (parts.length == 2) {
              double whole = double.tryParse(parts[0]) ?? 0;
              if (parts[1].contains('/')) {
                final fracParts = parts[1].split('/');
                if (fracParts.length == 2) {
                  double num = double.tryParse(fracParts[0]) ?? 0;
                  double den = double.tryParse(fracParts[1]) ?? 1;
                  quantity = whole + (den == 0 ? 0 : num / den);
                } else {
                   quantity = whole + (double.tryParse(parts[1]) ?? 0); // e.g. "1 0.5"
                }
              } else { // e.g. "1 0.5"
                quantity = whole + (double.tryParse(parts[1]) ?? 0);
              }
            }
          } else if (qtyStr.contains('/')) { // Simple fraction "1/2"
            final parts = qtyStr.split('/');
            if (parts.length == 2) {
              double num = double.tryParse(parts[0]) ?? 0;
              double den = double.tryParse(parts[1]) ?? 1;
              quantity = den == 0 ? 0 : num / den;
            } else {
               quantity = double.tryParse(qtyStr) ?? 1.0; // Fallback
            }
          } else { // Decimal or whole number
            quantity = double.tryParse(qtyStr) ?? 1.0;
          }
        }

        // Determine unit and name
        if (nameRemainderStr != null && nameRemainderStr.isNotEmpty) {
            if (unitOrFirstNamePart != null) {
                 // Heuristic: common units. This list can be expanded.
                const commonUnits = ['cup', 'cups', 'oz', 'g', 'kg', 'lb', 'lbs', 'ml', 'l', 'tsp', 'tbsp', 'tablespoon', 'teaspoon', 'pinch', 'slice', 'slices', 'clove', 'cloves'];
                if (commonUnits.contains(unitOrFirstNamePart.toLowerCase())) {
                    unit = unitOrFirstNamePart;
                    name = nameRemainderStr.trim();
                } else {
                    // unitOrFirstNamePart is likely part of the name
                    name = (unitOrFirstNamePart + " " + nameRemainderStr).trim();
                }
            } else {
                 name = nameRemainderStr.trim();
            }
        } else if (unitOrFirstNamePart != null) {
            // If nameRemainderStr is empty, unitOrFirstNamePart is the name
            name = unitOrFirstNamePart.trim();
        }
        // If qtyStr was null, name is already `line`
         if (qtyStr == null && unitOrFirstNamePart != null && nameRemainderStr != null) {
             // This case handles "Unit Name", e.g. "Pinch salt"
             const commonUnits = ['cup', 'cups', 'oz', 'g', 'kg', 'lb', 'lbs', 'ml', 'l', 'tsp', 'tbsp', 'tablespoon', 'teaspoon', 'pinch', 'slice', 'slices', 'clove', 'cloves'];
             if(commonUnits.contains(unitOrFirstNamePart.toLowerCase())) {
                 unit = unitOrFirstNamePart;
                 name = nameRemainderStr.trim();
                 quantity = 1.0; // Default quantity if not specified but unit is
             } else {
                 name = line; // Treat as "Name"
             }
         } else if (qtyStr == null && unitOrFirstNamePart != null && nameRemainderStr == null) {
            // Handles just "Name" or "Unit"
            name = unitOrFirstNamePart.trim();
         }


      } // else: name remains `line`, quantity 1.0, unit null

      ingredients.add(RecipeIngredientModel(
        ingredient_text: name, // name variable here holds the full ingredient text
        quantity: quantity,
        unit: unit,
        order_index: i,
      ));
    }
    return ingredients;
  }

  List<RecipeInstructionModel> _parseInstructions(String text) {
    final List<RecipeInstructionModel> instructions = [];
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    // Regex to find "[img:URL]" at the end of the line.
    // It captures the main instruction text in group 1, and the URL in group 3 (group 2 is the non-capturing ?:).
    final RegExp imgRegex = RegExp(r'^(.*?)(?:\s*\[img:(.+?)\])?\s*$');

    for (int i = 0; i < lines.length; i++) {
      String instructionTextFull = lines[i].trim();
      String instructionTextFinal = instructionTextFull;
      String? imageUrl;

      final match = imgRegex.firstMatch(instructionTextFull);
      if (match != null) {
        instructionTextFinal = match.group(1)?.trim() ?? ''; // The instruction part
        imageUrl = match.group(2)?.trim(); // The URL part, if it exists
        if (imageUrl != null && imageUrl.isEmpty) {
          imageUrl = null; // Treat empty [img:] or [img: ] as null
        }
      }

      instructions.add(RecipeInstructionModel(
        step_number: i + 1,
        instruction: instructionTextFinal,
        image_url: imageUrl,
      ));
    }
    return instructions;
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

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
        }
      }
    }

    const String hardcodedUserId = '325c40cc-d255-4f93-bf5f-40bc196ca093'; // Per instructions

    final List<RecipeIngredientModel> ingredients = _parseIngredients(_ingredientsController.text);

    // New logic for instructions
    List<RecipeInstructionModel> finalInstructions = [];
    for (int i = 0; i < _instructionSteps.length; i++) {
      InstructionStepData stepData = _instructionSteps[i];
      String instructionText = stepData.textController.text.trim();
      String? imageUrl = stepData.existingImageUrl; // Will be null for new recipes

      if (stepData.selectedImageFile != null) {
        // Upload new image
        final String? uploadedUrl = await _imageUploadService.uploadImage(stepData.selectedImageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          // Handle image upload failure for this step - e.g., log it or notify user
          print('Failed to upload image for instruction step ${i + 1}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image for step ${i + 1}. It will be skipped.')),
            );
          }
        }
      }

      if (instructionText.isNotEmpty) {
        finalInstructions.add(RecipeInstructionModel(
          step_number: i + 1,
          instruction: instructionText,
          image_url: imageUrl,
        ));
      }
    }

    RecipeModel recipeToCreate = RecipeModel(
      user_id: hardcodedUserId,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      image_url: mainImageUrl,
      calories: int.tryParse(_caloriesController.text),
      servings: int.tryParse(_servingsController.text) ?? 1,
      cooking_time_minutes: int.parse(_cookingMinutesController.text),
      difficulty_level: _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
      is_published: true,
      ingredients_text: _ingredientsController.text.isEmpty ? null : _ingredientsController.text,
      directions_text: null, // No longer a single text block
      ingredients: ingredients,
      instructions: finalInstructions, // Use the processed list
      gallery_image_urls: galleryImageUrls,
    );

    try {
      await _recipeService.createRecipe(recipeToCreate, galleryImageUrls);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe created successfully!')),
        );
        Navigator.pop(context, true);
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
    if (_isUploadingOrSaving) return;
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
                  onPressed: _isUploadingOrSaving ? null : _pickImage,
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
                    hintText: '1 cup flour\n2 eggs\n1/2 tsp salt...',
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
                    hintText: 'Mix flour and eggs.\nBake for 30 mins [img:http://example.com/bake.png]\n...',
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
                        key: const Key('pick_gallery_images_button'), 
                        onPressed: _isUploadingOrSaving ? null : _pickGalleryImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add Gallery Images'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedGalleryImageFiles.isNotEmpty)
                        SizedBox(
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
                _isUploadingOrSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
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
