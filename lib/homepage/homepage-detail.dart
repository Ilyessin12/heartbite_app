import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List;
import 'dart:ui';

// Import models and widgets from homepage.dart
import 'homepage.dart' show RecipeItem, RecipeCard;
// Import bottom navigation bar
import '../bottomnavbar/bottom-navbar.dart';

class HomePageDetailScreen extends StatefulWidget {
  final String title;
  final List<RecipeItem> recipes;

  const HomePageDetailScreen({
    Key? key,
    required this.title,
    required this.recipes,
  }) : super(key: key);

  @override
  State<HomePageDetailScreen> createState() => _HomePageDetailScreenState();
}

class _HomePageDetailScreenState extends State<HomePageDetailScreen> {
  late List<RecipeItem> _currentRecipes; // To hold the state of recipes
  int _currentIndex = 0; // Assuming Home is index 0 for BottomNavBar

  @override
  void initState(){
    super.initState();
    // Initialize with a copy to manage state locally
    _currentRecipes = List<RecipeItem>.from(widget.recipes.map((recipe) =>
      RecipeItem(
        id: recipe.id,
        name: recipe.name,
        rating: recipe.rating,
        reviewCount: recipe.reviewCount,
        calories: recipe.calories,
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        imagePath: recipe.imagePath,
        isBookmarked: recipe.isBookmarked,
      )
    ));
  }

  void _toggleBookmark(String recipeId){
    setState((){
      final index = _currentRecipes.indexWhere((recipe) => recipe.id == recipeId);
      if(index != -1){
        _currentRecipes[index].isBookmarked = !_currentRecipes[index].isBookmarked;
        // Optional: You might want to propagate this change back to the HomePage
        // using a callback or state management solution if needed.
      }
    });
  }

  void _onBottomNavTapped(int index){
    setState((){
      _currentIndex = index;
    });
    // Handle navigation based on index
    if(index == 0){
      // Navigate back to Home or handle appropriately
      if(Navigator.canPop(context)){
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      print('Navigate to Home');
    } else if(index == 1){
      // Navigate to Bookmark screen (replace with your actual navigation)
      print('Navigate to Bookmark');
    }
    // Add other navigation logic if needed
  }

  void _onFabPressed(){
    // Handle FAB press action (e.g., navigate to create recipe screen)
    print('FAB pressed on HomePageDetailScreen');
  }

  @override
  Widget build(BuildContext context){
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
                itemBuilder: (context, index){
                  return RecipeCard(
                    recipe: _currentRecipes[index],
                    onBookmarkTap: () => _toggleBookmark(_currentRecipes[index].id),
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