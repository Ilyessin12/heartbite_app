import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import '../../services/bookmark_service.dart';
import '../../services/image_upload_service.dart';
import '../../recipe/create_recipe_screen.dart';
import '../models/recipe_item.dart';
import '../widgets/recipe_card.dart';

class BookmarkCreateScreen extends StatefulWidget {
  const BookmarkCreateScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkCreateScreen> createState() => _BookmarkCreateScreenState();
}

class _BookmarkCreateScreenState extends State<BookmarkCreateScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<RecipeItem> _selectedRecipes = [];
  List<RecipeItem> _availableRecipes = [];
  bool _isSelectingCover = false;
  bool _isSelectingRecipes = true;
  bool _isLoadingRecipes = false;

  final List<String> _coverOptions = [
    'assets/images/cookbooks/placeholder_image.jpg',
    'assets/images/cookbooks/placeholder_image.jpg',
    'assets/images/cookbooks/placeholder_image.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableRecipes();
  }

  Future<void> _loadAvailableRecipes() async {
    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      // Load from saved recipes instead of all public recipes
      final recipesData = await _bookmarkService.getSavedRecipes();
      setState(() {
        _availableRecipes =
            recipesData.map((data) => RecipeItem.fromJson(data)).toList();
        _isLoadingRecipes = false;
      });
    } catch (e) {
      print("Error loading saved recipes: $e");
      setState(() {
        _isLoadingRecipes = false;
      });

      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No saved recipes found. Please save some recipes first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void handleBottomNavTap(int index) {
    if (index == 0) {
      // Navigate back to Homepage
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      // Navigate to main bookmark screen
      Navigator.pop(context);
    }
  }

  Future<void> createBookmark() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipe')),
      );
      return;
    }

    try {
      // Upload image to Cloudinary first
      String? finalImageUrl;
      if (_selectedImage != null) {
        finalImageUrl = await _imageUploadService.uploadImage(_selectedImage!);
        if (finalImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image upload failed. Please try again.'),
            ),
          );
          return;
        }
      }

      final recipeIds =
          _selectedRecipes
              .where((recipe) => recipe.id != null)
              .map((recipe) => recipe.id!)
              .toList();

      await _bookmarkService.createBookmarkFolder(
        name: _titleController.text.trim(),
        imageUrl:
            finalImageUrl ?? 'assets/images/cookbooks/placeholder_image.jpg',
        recipeIds: recipeIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark folder created successfully')),
      );

      Navigator.popUntil(
        context,
        (route) => route.isFirst || route.settings.name == '/bookmark',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating bookmark: $e')));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isSelectingCover = false;
          _isSelectingRecipes = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.dmSans()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera', style: GoogleFonts.dmSans()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(
                  'Select from templates',
                  style: GoogleFonts.dmSans(),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isSelectingCover = true;
                    _isSelectingRecipes = false;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleRecipeSelection(RecipeItem recipe) {
    setState(() {
      final isSelected = _selectedRecipes.any(
        (item) => item.name == recipe.name,
      );

      if (isSelected) {
        _selectedRecipes.removeWhere((item) => item.name == recipe.name);
      } else {
        _selectedRecipes.add(recipe);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelectingRecipes) {
      return _buildRecipeSelectionScreen();
    } else if (_isSelectingCover) {
      return _buildCoverSelectionScreen();
    } else {
      return _buildMainCreateScreen();
    }
  }

  Widget _buildMainCreateScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Bookmark',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSelectingRecipes = true;
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create Cookbook',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF8E1616),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image:
                            (_selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : const AssetImage(
                                      'assets/images/cookbooks/placeholder_image.jpg',
                                    ))
                                as ImageProvider,
                      ),
                    ),
                    child:
                        _selectedImage == null
                            ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                                size: 40,
                              ),
                            )
                            : null,
                  ),
                ),

                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    child: Text(
                      'Change Cover',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: const Color(0xFF8E1616),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E0E0).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Title',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: createBookmark,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1616),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Create',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: handleBottomNavTap,
        onFabPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
          );
          if (result == true) {
            // Refresh if needed
          }
        },
      ),
    );
  }

  Widget _buildCoverSelectionScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Bookmark',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSelectingCover = false;
              _isSelectingRecipes = false;
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Change Cover',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _coverOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                          print("Selected template: ${_coverOptions[index]}");
                          _isSelectingCover = false;
                          _isSelectingRecipes = false;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _coverOptions[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: handleBottomNavTap,
        onFabPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
          );
          if (result == true) {
            // Refresh if needed
          }
        },
      ),
    );
  }

  Widget _buildRecipeSelectionScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Bookmark',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E0E0),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF8E1616)),
              onPressed: () {
                if (_selectedRecipes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih setidaknya satu resep.'),
                    ),
                  );
                  return;
                }
                setState(() {
                  _isSelectingRecipes = false;
                  _isSelectingCover = false;
                });
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add From',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedRecipes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${_selectedRecipes.length} item terpilih',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoadingRecipes
                      ? const Center(child: CircularProgressIndicator())
                      : _availableRecipes.isEmpty
                      ? Center(
                        child: Text(
                          'Tidak ada resep tersimpan.',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                        itemCount: _availableRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _availableRecipes[index];
                          final isSelected = _selectedRecipes.any(
                            (item) => item.name == recipe.name,
                          );

                          return GestureDetector(
                            onTap: () {
                              _toggleRecipeSelection(recipe);
                            },
                            child: Stack(
                              children: [
                                RecipeCard(recipe: recipe),
                                if (isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  const Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: handleBottomNavTap,
        onFabPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
          );
          if (result == true) {
            // Refresh if needed
          }
        },
      ),
    );
  }
}
