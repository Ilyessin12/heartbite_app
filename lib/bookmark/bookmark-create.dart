import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import bottom navigation components
import '../bottomnavbar/bottom-navbar.dart';
import 'bookmark.dart' show BookmarkCategory, RecipeItem; // Keep RecipeItem import

class BookmarkCreateScreen extends StatefulWidget{
  // Add parameter to accept saved recipes
  final List<RecipeItem> savedRecipes;

  const BookmarkCreateScreen({Key? key, required this.savedRecipes}) : super(key: key);

  @override
  State<BookmarkCreateScreen> createState() => _BookmarkCreateScreenState();
}

class _BookmarkCreateScreenState extends State<BookmarkCreateScreen>{
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<RecipeItem> _selectedRecipes = [];
  bool _isSelectingCover = false;
  // Start with recipe selection screen
  bool _isSelectingRecipes = true;

  // Sample cover options
  final List<String> _coverOptions = [
    'assets/images/cookbooks/placeholder_image.jpg',
    'assets/images/cookbooks/placeholder_image.jpg',
    'assets/images/cookbooks/placeholder_image.jpg',
  ];

  // REMOVE the hardcoded _availableRecipes list
  // final List<RecipeItem> _availableRecipes = [ ... ];

  @override
  void dispose(){
    _titleController.dispose();
    super.dispose();
  }

  void handleBottomNavTap(int index){
    // In a real app, you'd navigate to different screens
    print('Navigated to index: $index');
     // Example: Navigate to Home if index 0 is tapped
    if(index == 0){
       if(Navigator.canPop(context)){
         Navigator.popUntil(context, (route) => route.isFirst);
       }
    }
    else if(index == 1){ // Bookmark index
        // If already on a create/edit screen within bookmark, pop back to main bookmark screen
        if(Navigator.canPop(context)){
            Navigator.popUntil(context, ModalRoute.withName('/bookmark')); // Assuming '/bookmark' is your main bookmark route name
        }
    }
  }

  void createBookmark(){
    // Validate input
    if(_titleController.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if(_selectedRecipes.isEmpty){
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipe')),
      );
      return;
    }

    // Create new bookmark category
    final newCategory = BookmarkCategory(
      name: _titleController.text.trim(),
      imageUrl: _selectedImage?.path ?? 'assets/images/cookbooks/placeholder_image.jpg', // Use selected image path or default
      recipes: List.from(_selectedRecipes), // Use a copy
    );

    // In a real app, you would pass this newCategory back to BookmarkScreen
    // using Navigator.pop(context, newCategory) and handle it in the .then()
    print('Created bookmark: ${newCategory.name} with ${newCategory.recipes.length} recipes');
    print('Image URL: ${newCategory.imageUrl}');

    // Navigate back to the main bookmark screen
    // Pop twice: once for the create screen, once for the recipe selection screen
    int popCount = 0;
    Navigator.popUntil(context, (route){
        popCount++;
        // Pop until we are back at the main bookmark screen or the root
        // Adjust '/bookmark' if your main bookmark screen route name is different
        return route.isFirst || route.settings.name == '/bookmark' || popCount >= 2;
    });
  }


  Future<void> _pickImage(ImageSource source) async{
    try{
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if(pickedFile != null){
        setState((){
          _selectedImage = File(pickedFile.path);
          _isSelectingCover = false; // Go back to main create screen after picking
          _isSelectingRecipes = false; // Ensure we are not in recipe selection
        });
      }
    }
    catch(e){
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }


  void _showImageSourceOptions() async{
    showModalBottomSheet(
      context: context,
      builder: (context){
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.dmSans()),
                onTap: (){
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera', style: GoogleFonts.dmSans()),
                onTap: (){
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text('Select from templates', style: GoogleFonts.dmSans()),
                onTap: (){
                  Navigator.of(context).pop();
                  setState((){
                    _isSelectingCover = true;
                    _isSelectingRecipes = false; // Ensure we are not in recipe selection
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleRecipeSelection(RecipeItem recipe){
    setState((){
      // Check if the recipe is already selected using a unique identifier if available (like an ID)
      // For now, using name as a proxy for uniqueness
      final isSelected = _selectedRecipes.any((item) => item.name == recipe.name);

      if(isSelected){
        _selectedRecipes.removeWhere((item) => item.name == recipe.name);
      }
      else {
        _selectedRecipes.add(recipe);
      }
    });
  }

  @override
  Widget build(BuildContext context){
    // Determine which screen to show based on state flags
    if(_isSelectingRecipes){
      return _buildRecipeSelectionScreen();
    }
    else if(_isSelectingCover){
      return _buildCoverSelectionScreen();
    }
    else {
      return _buildMainCreateScreen();
    }
  }

  Widget _buildMainCreateScreen(){
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
          // Go back to recipe selection if coming from there
          onPressed: (){ setState((){ _isSelectingRecipes = true; }); },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subtitle
                Text(
                  'Create Cookbook',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Image with border
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF8E1616), // Changed border color
                        width: 2, // Adjusted border width
                      ),
                      borderRadius: BorderRadius.circular(8),
                      // Show selected image or placeholder
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: (_selectedImage != null
                                ? FileImage(_selectedImage!)
                                : const AssetImage('assets/images/cookbooks/placeholder_image.jpg'))
                            as ImageProvider,
                      ),
                    ),
                    // Optional: Add an icon if no image is selected
                    child: _selectedImage == null
                        ? const Center(
                            child: Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                            size: 40,
                          ))
                        : null,
                  ),
                ),


                // Change cover text
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

                // Title text field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E0E0).withOpacity(0.5), // Lighter background
                    borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.grey.shade300), // Subtle border
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
                        color: Colors.grey.shade500, // Lighter hint text
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Create button
                SizedBox( // Use SizedBox for consistent width
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: createBookmark,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1616),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2, // Add subtle shadow
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
        currentIndex: 1, // 1 for bookmark screen
        onTap: handleBottomNavTap,
        onFabPressed: (){
          // Handle FAB pressed action
          print('FAB pressed on BookmarkCreateScreen');
        },
      ),
    );
  }

  Widget _buildCoverSelectionScreen(){
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
          onPressed: (){
            setState((){
              _isSelectingCover = false; // Go back to main create screen
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
                // Subtitle
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

                // Grid of cover options
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7, // Adjust aspect ratio if needed
                  ),
                  itemCount: _coverOptions.length,
                  itemBuilder: (context, index){
                    return GestureDetector(
                      onTap: (){
                        setState((){
                          _selectedImage = null; // Clear any camera/gallery selection
                          // Store the selected template path (or identifier)
                          // For now, just using the placeholder path
                          // In a real app, you might copy this asset or store its path
                          // _selectedImage = File(_coverOptions[index]); // This won't work directly for assets
                          print("Selected template: ${_coverOptions[index]}");
                          _isSelectingCover = false; // Go back to main create screen
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
        currentIndex: 1, // 1 for bookmark screen
        onTap: handleBottomNavTap,
        onFabPressed: (){
          // Handle FAB pressed action
          print('FAB pressed on CoverSelectionScreen');
        },
      ),
    );
  }

  Widget _buildRecipeSelectionScreen(){
    // Use widget.savedRecipes here
    final List<RecipeItem> availableRecipes = widget.savedRecipes;

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
          // Pop back to the main bookmark screen if back is pressed here
          onPressed: (){ Navigator.of(context).pop(); },
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
              onPressed: (){
                // Proceed only if at least one recipe is selected
                if(_selectedRecipes.isEmpty){
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih setidaknya satu resep.')),
                  );
                  return;
                }
                setState((){
                  _isSelectingRecipes = false; // Move to the main create screen
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
                  if(_selectedRecipes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${_selectedRecipes.length} item terpilih', // Bahasa Indonesia
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved', // Title indicating source
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // Use the passed-in list
              child: availableRecipes.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada resep tersimpan.',
                      style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7, // Adjust as needed
                  ),
                  itemCount: availableRecipes.length,
                  itemBuilder: (context, index){
                    final recipe = availableRecipes[index];
                    // Check if the current recipe is selected
                    final isSelected = _selectedRecipes.any((item) => item.name == recipe.name);

                    return GestureDetector(
                      onTap: (){ _toggleRecipeSelection(recipe); },
                      child: Stack(
                        children: [
                          // Use the existing RecipeCard widget
                          RecipeCard(recipe: recipe),
                          // Overlay selection indicator
                          if(isSelected)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3), // Dark overlay
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if(isSelected)
                            const Positioned(
                              top: 10,
                              left: 10,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white, // White checkmark
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
        currentIndex: 1, // 1 for bookmark screen
        onTap: handleBottomNavTap,
        onFabPressed: (){
          // Handle FAB pressed action
          print('FAB pressed on RecipeSelectionScreen');
        },
      ),
    );
  }
}


// Re-use RecipeCard from bookmark-detail.dart or bookmark.dart if identical
// If slightly different, keep it here or move to a shared location.
class RecipeCard extends StatelessWidget{
  final RecipeItem recipe;

  const RecipeCard({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Recipe image
          Positioned.fill( // Use Positioned.fill for aspect ratio control
            child: Image.asset(
              'assets/images/cookbooks/placeholder_image.jpg', // Use recipe.imageUrl
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay for text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          // Bookmark icon (Optional: maybe show if it's bookmarked in general?)
          Positioned(
            top: 10,
            right: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // Use BookmarkSolid from iconoir if available and appropriate
                  child: const Icon(
                    Icons.bookmark, // Default icon
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          // Recipe details overlaid on image
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent column from taking full height
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.rating} (${recipe.reviewCount} ulasan)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Recipe name
                Text(
                  recipe.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Recipe info with dividers
                FittedBox( // Use FittedBox to prevent overflow if text is too long
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${recipe.calories} Cal',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, // Adjusted font size
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('|', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      Text(
                        '${recipe.prepTime} Porsi',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('|', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      Text(
                        '${recipe.cookTime} min',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}