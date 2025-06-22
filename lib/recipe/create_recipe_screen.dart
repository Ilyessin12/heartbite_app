import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';
import '../models/tag_models.dart'; // Added import for tag models
import '../services/auth_service.dart'; // Added import

// Data class for managing individual ingredient row inputs
class IngredientRowData {
  final UniqueKey id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  IngredientRowData({
    String initialName = '',
    String initialQuantity = '',
    String initialUnit = '',
  }) : id = UniqueKey(),
       nameController = TextEditingController(text: initialName),
       quantityController = TextEditingController(text: initialQuantity),
       unitController = TextEditingController(text: initialUnit);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }

  // Helper to check if the row is effectively empty (ignoring whitespace)
  bool get isEmpty {
    return nameController.text.trim().isEmpty &&
           quantityController.text.trim().isEmpty &&
           unitController.text.trim().isEmpty;
  }
}

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
  final List<File> _selectedGalleryImageFiles = []; // Made final

  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final RecipeService _recipeService = RecipeService();
  bool _isUploadingOrSaving = false;

  final _caloriesController = TextEditingController();
  final _servingsController = TextEditingController(text: '1'); // Default Porsi
  final _cookingMinutesController = TextEditingController();
  String? _selectedDifficultyLevel; 

  final List<IngredientRowData> _ingredientRows = []; // Made final
  final List<InstructionStepData> _instructionSteps = []; // Made final

  // State for tags - these are re-assigned in _fetchTags
  List<Allergen> _availableAllergens = [];
  List<DietProgram> _availableDietPrograms = [];
  List<Equipment> _availableEquipment = [];

  final Set<int> _selectedAllergenIds = {}; // Made final
  final Set<int> _selectedDietProgramIds = {}; // Made final
  final Set<int> _selectedEquipmentIds = {}; // Made final

  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    if (_ingredientRows.isEmpty) {
      _ingredientRows.add(IngredientRowData()); // Tambah satu baris bahan awal
    }
    if (_instructionSteps.isEmpty) {
      _instructionSteps.add(InstructionStepData());
    }
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    try {
      final allergens = await _recipeService.getAllergens();
      final dietPrograms = await _recipeService.getDietPrograms();
      final equipment = await _recipeService.getEquipment();
      if (!mounted) return;
      setState(() {
        _availableAllergens = allergens;
        _availableDietPrograms = dietPrograms;
        _availableEquipment = equipment;
        _isLoadingTags = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tag: $e')),
      );
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();
    _cookingMinutesController.dispose();
    // _difficultyLevelController.dispose(); // Dihapus
    // _ingredientsController.dispose(); // Diganti _ingredientRows
    for (var row in _ingredientRows) {
      row.dispose();
    }
    for (var step in _instructionSteps) {
      step.dispose();
    }
    super.dispose();
  }

  // _parseIngredients sudah tidak relevan karena input bahan sekarang terstruktur
  // Logika konversi dari IngredientRowData ke RecipeIngredientModel akan ada di _saveRecipe

  double _parseQuantity(String quantityStr) {
    quantityStr = quantityStr.trim().replaceAll(',', '.'); // Ganti koma dengan titik untuk desimal
    if (quantityStr.isEmpty) return 1.0; // Default jika kosong

    if (quantityStr.contains('/')) { // Handle fraksi seperti "1/2" atau "1 1/2"
        final parts = quantityStr.split(' ');
        double totalQuantity = 0;
        if (parts.length > 1) { // Format seperti "1 1/2"
            totalQuantity += double.tryParse(parts[0]) ?? 0;
            final fractionParts = parts[1].split('/');
            if (fractionParts.length == 2) {
                double numerator = double.tryParse(fractionParts[0]) ?? 0;
                double denominator = double.tryParse(fractionParts[1]) ?? 1;
                if (denominator != 0) {
                    totalQuantity += numerator / denominator;
                }
            }
        } else { // Format seperti "1/2"
            final fractionParts = quantityStr.split('/');
            if (fractionParts.length == 2) {
                double numerator = double.tryParse(fractionParts[0]) ?? 0;
                double denominator = double.tryParse(fractionParts[1]) ?? 1;
                if (denominator != 0) {
                    totalQuantity = numerator / denominator;
                } else {
                    totalQuantity = 0; // Atau handle error
                }
            } else { // Bukan fraksi valid, coba parse sebagai double biasa
                 return double.tryParse(quantityStr) ?? 1.0;
            }
        }
        return totalQuantity > 0 ? totalQuantity : 1.0;
    } else { // Bukan fraksi, parse sebagai double biasa
        return double.tryParse(quantityStr) ?? 1.0;
    }
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
    if (!AuthService.isUserLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk untuk menyimpan resep.')),
      );
      setState(() { // This setState is fine as it's after the return if not mounted.
        _isUploadingOrSaving = false;
      });
      return;
    }

    if (_selectedImageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gambar utama resep.')),
      );
      return;
    }

    if (_selectedDifficultyLevel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tingkat kesulitan.')),
      );
      return;
    }

    if (_instructionSteps.isEmpty || _instructionSteps.every((step) => step.textController.text.trim().isEmpty)) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tambahkan minimal satu langkah instruksi dengan teks.')),
      );
      return;
    }


    if (!_formKey.currentState!.validate()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap perbaiki kesalahan dalam formulir sebelum menyimpan.')),
      );
      return;
    }
    _formKey.currentState!.save();

    if (_isUploadingOrSaving) return;

    setState(() {
      _isUploadingOrSaving = true;
    });

    String? mainImageUrl;
    mainImageUrl = await _imageUploadService.uploadImage(_selectedImageFile!);
    if (mainImageUrl == null) {
      // Mounted check for setState and SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unggah gambar utama resep gagal. Silakan coba lagi.')),
      );
      setState(() { _isUploadingOrSaving = false; });
      return;
    }

    // Proses Ingredients dari _ingredientRows
    List<RecipeIngredientModel> processedIngredients = [];
    String ingredientsTextConcatenated = ""; // Untuk mengisi RecipeModel.ingredients_text

    for (int i = 0; i < _ingredientRows.length; i++) {
      final row = _ingredientRows[i];
      final name = row.nameController.text.trim();
      final quantityStr = row.quantityController.text.trim();
      final unit = row.unitController.text.trim();

      if (name.isEmpty && quantityStr.isEmpty && unit.isEmpty) {
        continue; // Lewati baris kosong
      }

      if (name.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nama bahan di baris ${i + 1} tidak boleh kosong jika baris tidak sepenuhnya kosong.')));
        setState(() { _isUploadingOrSaving = false; });
        return;
      }
       if (quantityStr.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah bahan di baris ${i + 1} tidak boleh kosong jika nama bahan diisi.')));
        setState(() { _isUploadingOrSaving = false; });
        return;
      }

      double quantity = _parseQuantity(quantityStr);
      if (quantity <= 0 && quantityStr.isNotEmpty) { 
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah bahan "$name" tidak valid (harus lebih besar dari 0).')));
           setState(() { _isUploadingOrSaving = false; });
           return;
      }


      processedIngredients.add(RecipeIngredientModel(
        ingredient_text: name, 
        quantity: quantity,
        unit: unit.isNotEmpty ? unit : null,
        order_index: processedIngredients.length,
      ));
      ingredientsTextConcatenated += "$quantityStr $unit $name\n";
    }

    if (processedIngredients.isEmpty && _ingredientRows.any((row) => !row.isEmpty)) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan minimal satu bahan dengan nama dan jumlah yang valid.')));
       setState(() { _isUploadingOrSaving = false; });
       return;
    }
     if (processedIngredients.isEmpty && _ingredientRows.every((row) => row.isEmpty) && _ingredientRows.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resep harus memiliki minimal satu bahan.')));
        setState(() { _isUploadingOrSaving = false; });
        return;
    }


    List<String> galleryImageUrls = [];
    if (_selectedGalleryImageFiles.isNotEmpty) {
      for (File imageFile in _selectedGalleryImageFiles) {
        String? url = await _imageUploadService.uploadImage(imageFile);
        if (url != null) {
          galleryImageUrls.add(url);
        } else {
          // print('Sebuah gambar galeri gagal diunggah dan akan dilewati.'); // Removed print
           if (!mounted) return; // Check before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sebuah gambar galeri gagal diunggah dan dilewati.')),
            );
          // Not returning here, just skipping the image
        }
      }
    }

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
          // print('Gagal mengunggah gambar untuk langkah instruksi ${i + 1}'); // Removed print
          if (!mounted) return; // Check before showing SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah gambar untuk langkah ${i + 1}. Gambar akan dilewati.')),
            );
           // Not returning, just skipping image
        }
      }

      if (instructionText.isNotEmpty) {
        finalInstructions.add(RecipeInstructionModel(
          step_number: i + 1,
          instruction: instructionText,
          image_url: imageUrl, 
        ));
      } else if (imageUrl != null && instructionText.isEmpty) {
         // print('Langkah instruksi ${i + 1} memiliki gambar tetapi tidak ada teks. Langkah ini akan dilewati.'); // Removed print
         if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Langkah instruksi ${i + 1} memiliki gambar tetapi tidak ada teks. Langkah ini dilewati.')),
            );
      }
    }

    RecipeModel recipeToCreate = RecipeModel(
      user_id: '',
      title: _titleController.text,
      description: _descriptionController.text,
      image_url: mainImageUrl,
      calories: int.parse(_caloriesController.text),
      servings: int.tryParse(_servingsController.text) ?? 1,
      cooking_time_minutes: int.parse(_cookingMinutesController.text),
      difficulty_level: _selectedDifficultyLevel!,
      is_published: true,
      ingredients_text: ingredientsTextConcatenated.trim().isNotEmpty ? ingredientsTextConcatenated.trim() : null,
      directions_text: null,
      ingredients: processedIngredients.isNotEmpty ? processedIngredients : null, 
      instructions: finalInstructions,
      gallery_image_urls: galleryImageUrls,
      selectedAllergenIds: _selectedAllergenIds.toList(),
      selectedDietProgramIds: _selectedDietProgramIds.toList(), 
      selectedEquipmentIds: _selectedEquipmentIds.toList(), 
    );

    try {
      await _recipeService.createRecipe(recipeToCreate, galleryImageUrls);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resep berhasil dibuat!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      // print('Error menyimpan resep: $e'); // Removed print
      if (!mounted) return;
      String errorMessage = 'Gagal membuat resep: $e';
      if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Silakan masuk untuk membuat resep.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) { // Check mounted before final setState
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
        title: Text('Buat Resep Baru', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
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
                  decoration: InputDecoration(labelText: 'Judul Resep*', labelStyle: labelStyle),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul resep tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('description_field'),
                  controller: _descriptionController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Deskripsi Resep*', labelStyle: labelStyle),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi resep tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Main Recipe Image Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("Gambar Utama Resep*", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                    if (_selectedImageFile != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          image: DecorationImage(
                            image: FileImage(_selectedImageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 100,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4.0)
                        ),
                        child: Center(child: Text("Belum ada gambar utama dipilih", style: labelStyle)),
                      ),
                    ElevatedButton.icon(
                      key: const Key('pick_image_button'),
                      onPressed: _isUploadingOrSaving ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_selectedImageFile == null ? 'Pilih Gambar Utama Resep' : 'Ganti Gambar Utama Resep'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('calories_field'),
                  controller: _caloriesController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Kalori* (contoh: 250)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kalori tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Masukkan jumlah kalori yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('servings_field'),
                  controller: _servingsController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Porsi* (contoh: 4)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah porsi tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Masukkan jumlah porsi yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('cooking_minutes_field'),
                  controller: _cookingMinutesController,
                  style: textStyle,
                  decoration: InputDecoration(labelText: 'Waktu Memasak (Menit)* (contoh: 30)', labelStyle: labelStyle),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Waktu memasak tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Masukkan waktu memasak yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Difficulty Level ChoiceChips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tingkat Kesulitan*", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text('Mudah', style: GoogleFonts.dmSans(fontSize: 13)),
                          selected: _selectedDifficultyLevel == 'easy',
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDifficultyLevel = selected ? 'easy' : null;
                            });
                          },
                          selectedColor: Colors.teal[100],
                          backgroundColor: Colors.grey[200],
                           shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedDifficultyLevel == 'easy' ? Colors.teal : Colors.grey[400]!,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          label: Text('Sedang', style: GoogleFonts.dmSans(fontSize: 13)),
                          selected: _selectedDifficultyLevel == 'medium',
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDifficultyLevel = selected ? 'medium' : null;
                            });
                          },
                          selectedColor: Colors.teal[100],
                          backgroundColor: Colors.grey[200],
                           shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedDifficultyLevel == 'medium' ? Colors.teal : Colors.grey[400]!,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          label: Text('Sulit', style: GoogleFonts.dmSans(fontSize: 13)),
                          selected: _selectedDifficultyLevel == 'hard',
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDifficultyLevel = selected ? 'hard' : null;
                            });
                          },
                          selectedColor: Colors.teal[100],
                          backgroundColor: Colors.grey[200],
                           shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedDifficultyLevel == 'hard' ? Colors.teal : Colors.grey[400]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Structured Ingredients Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bahan-Bahan*", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_ingredientRows.isEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 8.0),
                         child: Text("Belum ada bahan ditambahkan.", style: labelStyle),
                       ),
                    Column(
                      children: _ingredientRows.asMap().entries.map((entry) {
                        int idx = entry.key;
                        IngredientRowData rowData = entry.value;
                        return Card(
                          key: rowData.id,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: rowData.nameController,
                                        style: textStyle,
                                        decoration: InputDecoration(labelText: 'Nama Bahan*', labelStyle: labelStyle),
                                        validator: (value) {
                                          // Validasi per baris bisa dilakukan di _saveRecipe
                                          // Atau jika ingin validasi form, perlu lebih kompleks
                                          return null; 
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                     Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: rowData.quantityController,
                                        style: textStyle,
                                        decoration: InputDecoration(labelText: 'Jumlah*', labelStyle: labelStyle),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                         validator: (value) {
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: rowData.unitController,
                                        style: textStyle,
                                        decoration: InputDecoration(labelText: 'Satuan', labelStyle: labelStyle),
                                         validator: (value) {
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (_ingredientRows.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            rowData.dispose();
                                            _ingredientRows.removeAt(idx);
                                          });
                                        },
                                      )
                                    else // Placeholder for alignment if only one row and no remove button
                                       const SizedBox(width: 48), // Lebar IconButton
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
                          _ingredientRows.add(IngredientRowData());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Bahan'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100], foregroundColor: Colors.green[900]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Instruksi*", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_instructionSteps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Belum ada langkah instruksi ditambahkan.", style: labelStyle),
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
                                      labelText: 'Langkah ${idx + 1}*',
                                      hintText: 'Masukkan detail instruksi...',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                         return 'Teks instruksi tidak boleh kosong.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                // Tombol hapus hanya muncul jika ada lebih dari 1 langkah
                                if (_instructionSteps.length > 1 || (_instructionSteps.length == 1 && idx >0) ) // Logika untuk selalu bisa menghapus jika bukan satu-satunya
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
                                  label: Text(stepData.selectedImageFile == null && stepData.existingImageUrl == null ? 'Tambah Gambar (Opsional)' : 'Ganti Gambar (Opsional)'),
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
                                  )
                                else if (stepData.existingImageUrl != null) // Should not happen in create screen, but good for consistency
                                   Expanded(
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Image.network(
                                          stepData.existingImageUrl!,
                                          height: 60,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                                        ),
                                         // No clear button for existing images from URL in create mode
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
                  label: const Text('Tambah Langkah Instruksi'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[100], foregroundColor: Colors.teal[900]),
                ),
                const SizedBox(height: 24),

                // Tags Section (Opsional)
                if (_isLoadingTags)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildTagSelectionSection<Allergen>(
                    title: 'Alergen (Pilih jika ada)',
                    availableTags: _availableAllergens,
                    selectedTagIds: _selectedAllergenIds,
                    onSelected: (selected, tagId) {
                      setState(() {
                        if (selected) {
                          _selectedAllergenIds.add(tagId);
                        } else {
                          _selectedAllergenIds.remove(tagId);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTagSelectionSection<DietProgram>(
                    title: 'Program Diet (Pilih jika sesuai)',
                    availableTags: _availableDietPrograms,
                    selectedTagIds: _selectedDietProgramIds,
                    onSelected: (selected, tagId) {
                      setState(() {
                        if (selected) {
                          _selectedDietProgramIds.add(tagId);
                        } else {
                          _selectedDietProgramIds.remove(tagId);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTagSelectionSection<Equipment>(
                    title: 'Peralatan yang Dibutuhkan (Pilih jika ada)',
                    availableTags: _availableEquipment,
                    selectedTagIds: _selectedEquipmentIds,
                    onSelected: (selected, tagId) {
                      setState(() {
                        if (selected) {
                          _selectedEquipmentIds.add(tagId);
                        } else {
                          _selectedEquipmentIds.remove(tagId);
                        }
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Gallery Images (Opsional)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Gambar Galeri (Opsional)", style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        key: const Key('pick_gallery_images_button'),
                        onPressed: _isUploadingOrSaving ? null : _pickGalleryImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Tambah Gambar Galeri'),
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
                        )
                      else
                        Text("Belum ada gambar galeri ditambahkan.", style: labelStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _isUploadingOrSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      key: const Key('save_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthService.isUserLoggedIn() ? Colors.teal : Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: AuthService.isUserLoggedIn() ? _saveRecipe : null,
                      child: Text(AuthService.isUserLoggedIn() ? 'Simpan Data Resep' : 'Masuk untuk Menyimpan'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSelectionSection<T>({
    required String title,
    required List<T> availableTags,
    required Set<int> selectedTagIds,
    required Function(bool, int) onSelected,
  }) {
    final labelStyle = GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[700]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (availableTags.isEmpty && !_isLoadingTags)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Tidak ada ${title.toLowerCase().split(' ')[0]} tersedia.", style: labelStyle),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: availableTags.map((tag) {
              final tagId = (tag as dynamic).id as int;
              final tagName = (tag as dynamic).name as String;
              return ChoiceChip(
                label: Text(tagName, style: GoogleFonts.dmSans(fontSize: 13)),
                selected: selectedTagIds.contains(tagId),
                onSelected: (selected) {
                  onSelected(selected, tagId);
                },
                selectedColor: Colors.teal[100],
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selectedTagIds.contains(tagId) ? Colors.teal : Colors.grey[400]!,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
