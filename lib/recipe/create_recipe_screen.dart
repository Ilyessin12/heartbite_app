import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';

class InstructionStepData {
  final UniqueKey id;
  final TextEditingController textController;
  File? selectedImageFile;
  String? existingImageUrl;

  InstructionStepData({
    String initialText = '',
    this.selectedImageFile,
    this.existingImageUrl,
  }) : id = UniqueKey(), textController = TextEditingController(text: initialText);

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
  List<InstructionStepData> _instructionSteps = [];

  @override
  void initState() {
    super.initState();
    if (_instructionSteps.isEmpty) {
      _instructionSteps.add(InstructionStepData());
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
    for (var step in _instructionSteps) {
      step.dispose();
    }
    super.dispose();
  }

  List<RecipeIngredientModel> _parseIngredients(String text) {
    final List<RecipeIngredientModel> ingredients = [];
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final RegExp regex = RegExp(
      r'^\s*(?:([\d\.\/]+(?:\s+[\d\.\/]+)?)\s+)?'
      r'(?:(\S+)\s+)?'
      r'(.+)$'
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final match = regex.firstMatch(line);

      double quantity = 1.0;
      String? unit;
      String ingredientFullText = line;

      if (match != null) {
        String? qtyStr = match.group(1);
        String? unitOrFirstNamePart = match.group(2);
        String? nameRemainderStr = match.group(3);

        if (qtyStr != null) {
          qtyStr = qtyStr.trim();
          if (qtyStr.contains(' ')) {
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
                   quantity = whole + (double.tryParse(parts[1]) ?? 0);
                }
              } else {
                quantity = whole + (double.tryParse(parts[1]) ?? 0);
              }
            }
          } else if (qtyStr.contains('/')) {
            final parts = qtyStr.split('/');
            if (parts.length == 2) {
              double num = double.tryParse(parts[0]) ?? 0;
              double den = double.tryParse(parts[1]) ?? 1;
              quantity = den == 0 ? 0 : num / den;
            } else {
               quantity = double.tryParse(qtyStr) ?? 1.0;
            }
          } else {
            quantity = double.tryParse(qtyStr) ?? 1.0;
          }
        }

        if (nameRemainderStr != null && nameRemainderStr.isNotEmpty) {
            if (unitOrFirstNamePart != null) {
                const commonUnits = ['cup', 'cups', 'oz', 'g', 'kg', 'lb', 'lbs', 'ml', 'l', 'tsp', 'tbsp', 'tablespoon', 'teaspoon', 'pinch', 'slice', 'slices', 'clove', 'cloves'];
                if (commonUnits.contains(unitOrFirstNamePart.toLowerCase())) {
                    unit = unitOrFirstNamePart;
                    ingredientFullText = nameRemainderStr.trim();
                } else {
                    ingredientFullText = (unitOrFirstNamePart + " " + nameRemainderStr).trim();
                }
            } else {
                 ingredientFullText = nameRemainderStr.trim();
            }
        } else if (unitOrFirstNamePart != null) {
            ingredientFullText = unitOrFirstNamePart.trim();
        }
         if (qtyStr == null && unitOrFirstNamePart != null && nameRemainderStr != null) {
             const commonUnits = ['cup', 'cups', 'oz', 'g', 'kg', 'lb', 'lbs', 'ml', 'l', 'tsp', 'tbsp', 'tablespoon', 'teaspoon', 'pinch', 'slice', 'slices', 'clove', 'cloves'];
             if(commonUnits.contains(unitOrFirstNamePart.toLowerCase())) {
                 unit = unitOrFirstNamePart;
                 ingredientFullText = nameRemainderStr.trim();
                 quantity = 1.0;
             } else {
                 ingredientFullText = line;
             }
         } else if (qtyStr == null && unitOrFirstNamePart != null && nameRemainderStr == null) {
            ingredientFullText = unitOrFirstNamePart.trim();
         }
      }

      ingredients.add(RecipeIngredientModel(
        ingredient_text: ingredientFullText,
        quantity: quantity,
        unit: unit,
        order_index: i,
      ));
    }
    return ingredients;
  }

  Future<void> _pickInstructionImage(int index) async {
    if (_isUploadingOrSaving) return;
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _instructionSteps[index].selectedImageFile = File(pickedFile.path);
      });
    }
  }

  // Method to pick the main recipe image
  Future<void> _pickImage() async {
    if (_isUploadingOrSaving) return;
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  // Method to pick gallery images
  Future<void> _pickGalleryImages() async {
    if (_isUploadingOrSaving) return;
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        _selectedGalleryImageFiles.addAll(pickedFiles.map((xf) => File(xf.path)).toList());
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct errors in the form before saving.')),
      );
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
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A gallery image failed to upload and was skipped.')),
            );
          }
        }
      }
    }

    // const String hardcodedUserId = '325c40cc-d255-4f93-bf5f-40bc196ca093'; // No longer needed

    final List<RecipeIngredientModel> ingredients = _parseIngredients(_ingredientsController.text);

    List<RecipeInstructionModel> finalInstructions = [];
    for (int i = 0; i < _instructionSteps.length; i++) {
      InstructionStepData stepData = _instructionSteps[i];
      String instructionText = stepData.textController.text.trim();
      String? imageUrl = stepData.existingImageUrl;

      if (stepData.selectedImageFile != null) {
        final String? uploadedUrl = await _imageUploadService.uploadImage(stepData.selectedImageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          print('Failed to upload image for instruction step ${i + 1}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image for step ${i + 1}. It will be skipped.')),
            );
          }
        }
      }

      if (instructionText.isNotEmpty) { // Only add instruction if text is not empty
        finalInstructions.add(RecipeInstructionModel(
          step_number: i + 1,
          instruction: instructionText,
          image_url: imageUrl,
        ));
      } else if (imageUrl != null) {
         print('Instruction step ${i + 1} has an image but no text. It will be skipped.');
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Instruction step ${i + 1} has an image but no text. It was skipped.')),
            );
          }
      }
    }

    if (finalInstructions.isEmpty && _instructionSteps.isNotEmpty && _instructionSteps.every((s) => s.textController.text.trim().isEmpty && s.selectedImageFile == null)) {
        // If all instruction steps are effectively empty (no text, no image selected), treat as no instructions.
    }


    RecipeModel recipeToCreate = RecipeModel(
      // user_id will be set by RecipeService from the authenticated user
      user_id: '', // Provide a temporary non-null empty string, RecipeService will overwrite it.
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      image_url: mainImageUrl,
      calories: int.tryParse(_caloriesController.text),
      servings: int.tryParse(_servingsController.text) ?? 1,
      cooking_time_minutes: int.parse(_cookingMinutesController.text),
      difficulty_level: _difficultyLevelController.text.isEmpty ? 'medium' : _difficultyLevelController.text,
      is_published: true,
      ingredients_text: _ingredientsController.text.isEmpty ? null : _ingredientsController.text,
      directions_text: null,
      ingredients: ingredients,
      instructions: finalInstructions.isNotEmpty ? finalInstructions : null,
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
        String errorMessage = 'Failed to create recipe: ${e.toString()}';
        if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please log in to create a recipe.';
          // Optionally, navigate to login screen
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one ingredient.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Dynamic Instructions List
                Text("Instructions", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_instructionSteps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("No instruction steps added yet.", style: labelStyle),
                  ),
                Column(
                  children: _instructionSteps.asMap().entries.map((entry) {
                    int idx = entry.key;
                    InstructionStepData stepData = entry.value;
                    return Card(
                      key: stepData.id,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: stepData.textController,
                                    decoration: InputDecoration(
                                      labelText: 'Step ${idx + 1}',
                                      hintText: 'Enter instruction details...',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    validator: (value) {
                                      if (_instructionSteps.length > 1 && (value == null || value.isEmpty) && stepData.selectedImageFile == null) {
                                        // return 'Instruction cannot be empty if it\'s not the only step, or remove it.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_instructionSteps.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        stepData.dispose();
                                        _instructionSteps.removeAt(idx);
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _pickInstructionImage(idx),
                                  icon: const Icon(Icons.image_search),
                                  label: Text(stepData.selectedImageFile == null ? 'Add Image' : 'Change Image'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                                ),
                                const SizedBox(width: 10),
                                if (stepData.selectedImageFile != null)
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Image.file(
                                          stepData.selectedImageFile!,
                                          height: 60,
                                          fit: BoxFit.contain,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              stepData.selectedImageFile = null;
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _instructionSteps.add(InstructionStepData());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Instruction Step'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[100], foregroundColor: Colors.teal[900]),
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
