import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart'
    hide Key, Text, Navigator, List;
import 'dart:ui';

// Import models and widgets from homepage.dart
// Changed RecipeItem to DisplayRecipeItem
import 'homepage.dart' show DisplayRecipeItem, RecipeCard;
import '../recipe_detail/screens/recipe_detail_screen.dart'; // Import RecipeDetailScreen for onTap navigation
// Import bottom navigation bar
import '../bottomnavbar/bottom-navbar.dart';

class HomePageDetailScreen extends StatefulWidget {
  final String title;
  // Changed List<RecipeItem> to List<DisplayRecipeItem>
  final List<DisplayRecipeItem> recipes;

  const HomePageDetailScreen({
    Key? key,
    required this.title,
    required this.recipes,
  }) : super(key: key);

  @override
  State<HomePageDetailScreen> createState() => _HomePageDetailScreenState();
}

class _HomePageDetailScreenState extends State<HomePageDetailScreen> {
  // Changed List<RecipeItem> to List<DisplayRecipeItem>
  late List<DisplayRecipeItem> _currentRecipes;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with a copy, ensuring DisplayRecipeItem is used
    // The map operation might be redundant if widget.recipes is already a fresh list of DisplayRecipeItem
    // However, creating a new list ensures modifications here don't affect the original list passed to the widget.
    _currentRecipes = List<DisplayRecipeItem>.from(
      widget.recipes.map((recipe) {
        // Assuming recipe is already DisplayRecipeItem, we can copy it or use as is if no local modification needed
        // For safety, let's create new instances if DisplayRecipeItem has complex internal state or if we modify bookmark status etc.
        // If DisplayRecipeItem is simple and its fields are final (except isBookmarked), direct use after casting is also an option.
        final dr = recipe; // recipe is already DisplayRecipeItem here
        return DisplayRecipeItem(
          id: dr.id,
          name: dr.name,
          rating: dr.rating,
          reviewCount: dr.reviewCount,
          calories: dr.calories,
          servings: dr.servings, // Use servings
          cookingTimeMinutes: dr.cookingTimeMinutes, // Use cookingTimeMinutes
          imageUrl: dr.imageUrl, // Use imageUrl
          isBookmarked: dr.isBookmarked,
          allergens:
              dr.allergens, // Ensure these fields exist in DisplayRecipeItem
          dietTypes: dr.dietTypes,
          requiredAppliances: dr.requiredAppliances,
        );
      }),
    );
  }

  void _toggleBookmark(int recipeId) {
    // Changed to int recipeId
    setState(() {
      final index = _currentRecipes.indexWhere(
        (recipe) => recipe.id == recipeId,
      );
      if (index != -1) {
        _currentRecipes[index].isBookmarked =
            !_currentRecipes[index].isBookmarked;
      }
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Handle navigation based on index
    if (index == 0) {
      // Navigate to HomePage using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        ModalRoute.withName('/'),
      );
      print('Navigate to Home');
    } else if (index == 1) {
      // Navigate to Bookmark screen using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bookmark',
        ModalRoute.withName('/'),
      );
      print('Navigate to Bookmark');
    }
    // Add other navigation logic if needed
  }

  void _onFabPressed() {
    // Handle FAB press action (e.g., navigate to create recipe screen)
    print('FAB pressed on HomePageDetailScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8E1616)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search recipe', // Or use widget.title?
              hintStyle: GoogleFonts.dmSans(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10.0),
            ),
            style: GoogleFonts.dmSans(color: Colors.black),
          ),
        ),
        centerTitle: true, // Center the search bar
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Recipe Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.7, // Same as HomePage
                ),
                itemCount: _currentRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _currentRecipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  RecipeDetailScreen(recipeId: recipe.id),
                        ),
                      );
                    },
                    onBookmarkTap: () => _toggleBookmark(recipe.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex, // Reflect the current state
        onTap: _onBottomNavTapped,
        onFabPressed: _onFabPressed,
      ),
    );
  }
}
