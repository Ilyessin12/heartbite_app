import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';

// Import navigation components
import '../bottomnavbar/bottom-navbar.dart';
import 'bookmark-detail.dart';

// for routing to bookmark-create and bookmark-edit
import 'bookmark-create.dart';
import 'bookmark-edit.dart'; // Import BookmarkEditScreen

// Model for bookmark categories
class BookmarkCategory {
  final String name;
  final String imageUrl;
  final List<RecipeItem> recipes; // Recipes *in* this specific category folder
  bool isSelected;

  BookmarkCategory({
    required this.name,
    required this.imageUrl,
    required this.recipes,
    this.isSelected = false,
  });
}

// Model for recipe items
class RecipeItem {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int calories;
  final int prepTime; // Assuming this is Porsi (Servings)
  final int cookTime; // Assuming this is Menit (Minutes)

  RecipeItem({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.calories,
    required this.prepTime,
    required this.cookTime,
  });
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  // --- Central List of All Saved Recipes ---
  // Logically, all bookmarked items exist here first.
  final List<RecipeItem> allSavedRecipes = [
    RecipeItem(
      name: 'Roti Panggang Blueberry', // Was: Fruity blueberry toast
      imageUrl: 'placeholder_image.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 23,
      prepTime: 2, // Porsi
      cookTime: 12, // Menit
    ),
    RecipeItem(
      name: 'Roti Panggang Blackberry', // Was: Fruity blackberry toast
      imageUrl: 'placeholder_image.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 24,
      prepTime: 2, // Porsi
      cookTime: 12, // Menit
    ),
    // New recipes for Dinner (now also in Saved)
    RecipeItem(
      name: 'Nasi Goreng Spesial',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.5,
      reviewCount: 210,
      calories: 350,
      prepTime: 2, // Porsi
      cookTime: 20, // Menit
    ),
    RecipeItem(
      name: 'Ayam Bakar Madu',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.9,
      reviewCount: 305,
      calories: 420,
      prepTime: 4, // Porsi
      cookTime: 45, // Menit
    ),
    RecipeItem(
      name: 'Sate Ayam Bumbu Kacang',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.7,
      reviewCount: 180,
      calories: 380,
      prepTime: 3, // Porsi
      cookTime: 30, // Menit
    ),
  ];

  // --- User-Created Bookmark Categories/Folders ---
  // These folders *contain references* to recipes from `allSavedRecipes`.
  // Initially, they might be empty or pre-populated based on logic.
  // For this example, 'Saved' shows all, others are empty initially.
  late List<BookmarkCategory> categories;

  @override
  void initState() {
    super.initState();
    categories = [
      BookmarkCategory(
        name: 'Saved', // This special category shows ALL saved recipes
        imageUrl: 'placeholder_image.jpg',
        recipes: List.from(allSavedRecipes), // Contains all recipes
      ),
      BookmarkCategory(
        name: 'Resep Akhir Pekan', // Was: Weekend Recipe
        imageUrl: 'placeholder_image.jpg',
        recipes: [allSavedRecipes[0], allSavedRecipes[1]], // Initially empty, user adds recipes here from 'Saved'
      ),
      BookmarkCategory(
        name: 'Makan Malam', // Was: Dinner
        imageUrl: 'placeholder_image.jpg',
        recipes: [allSavedRecipes[2], allSavedRecipes[3], allSavedRecipes[4]], // Initially empty, user adds recipes here from 'Saved'
      ),
    ];
  }

  // Track selected categories for deletion
  Set<int> selectedCategories = {};

  void toggleCategorySelection(int index) {
    // Don't allow selection of "Saved" category for deletion/editing
    if (categories[index].name == 'Saved') {
      return;
    }

    setState(() {
      if (selectedCategories.contains(index)) {
        selectedCategories.remove(index);
      } else {
        selectedCategories.add(index);
      }
    });
  }

  void deleteSelectedCategories() {
    setState(() {
      // Sort in reverse order to avoid index shifting issues
      final toDelete =
          selectedCategories.toList()..sort((a, b) => b.compareTo(a));

      for (final index in toDelete) {
        // Ensure we don't delete the 'Saved' category
        if (categories[index].name != 'Saved') {
          categories.removeAt(index);
        }
      }

      // Clear selections after deletion
      selectedCategories.clear();
    });
  }

  void handleBottomNavTap(int index) {
    // In a real app, you'd navigate to different screens
    print('Navigated to index: $index');
    // Example: Navigate to Home if index 0 is tapped
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _navigateToEdit(BookmarkCategory category) {
    // Prevent editing the 'Saved' category
    if (category.name == 'Saved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kategori 'Saved' tidak bisa diedit.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookmarkEditScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title:
            selectedCategories.isNotEmpty
                ? Text(
                  '${selectedCategories.length} item terpilih', // Bahasa Indonesia
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
                : Text(
                  'Bookmark',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed:
              selectedCategories.isNotEmpty
                  ? () => setState(() => selectedCategories.clear())
                  : () => Navigator.of(context).pop(),
        ),
        actions: [
          selectedCategories.isNotEmpty
              ? IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFF8E1616)),
                onPressed: deleteSelectedCategories,
              )
              : Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E0E0),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF8E1616)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookmarkCreateScreen(savedRecipes: allSavedRecipes),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSavedCategory = category.name == 'Saved';
            return GestureDetector(
              onTap: () {
                if (selectedCategories.isNotEmpty) {
                  // Allow selection toggle only for non-'Saved' categories during multi-select
                  if (!isSavedCategory) {
                    toggleCategorySelection(index);
                  }
                } else {
                  // Navigate to category detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BookmarkDetailScreen(category: category),
                    ),
                  );
                }
              },
              onLongPress: () {
                // Allow long-press selection only for non-'Saved' categories
                if (!isSavedCategory) {
                  toggleCategorySelection(index);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Category image
                    Image.asset(
                      'assets/images/cookbooks/placeholder_image.jpg', // Use category.imageUrl if available
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Category name
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Text(
                        category.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Selection indicator
                    if (selectedCategories.contains(index))
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(
                              0.5,
                            ), // Semi-transparent background
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 24,
                            color: Color(0xFFAFF4C6),
                          ),
                        ),
                      ),
                    // Edit Icon (only when not selecting and not 'Saved')
                    if (selectedCategories.isEmpty && !isSavedCategory)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _navigateToEdit(category),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                0.4,
                              ), // Semi-transparent background
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              SolarIconsOutline.penNewSquare, // Or Icons.edit
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation bar with integrated FAB
          BottomNavBar(
            currentIndex: 1, // 1 for bookmark screen
            onTap: handleBottomNavTap,
            onFabPressed: () {
              // Handle FAB pressed action
              print('FAB pressed on BookmarkScreen');
            },
          ),
        ],
      ),
    );
  }
}