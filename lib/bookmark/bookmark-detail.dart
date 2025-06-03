import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List;
import 'dart:ui';

// Import bottom navigation bar
import '../bottomnavbar/bottom-navbar.dart';

// Import models from bookmark.dart
import 'bookmark.dart' show BookmarkCategory, RecipeItem;

// import from bookmark-edit.dart
// import 'bookmark-edit.dart' show BookmarkEditScreen; // No longer needed here

// import route for bookmark-create
import 'bookmark-create.dart';

class BookmarkDetailScreen extends StatelessWidget {
  final BookmarkCategory category;
  final List<RecipeItem> allSavedRecipes = [
    RecipeItem(
      name: 'Roti Panggang Blueberry', // Was: Fruity blueberry toast
      imageUrl: 'cookbooks/sandwich.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 23,
      prepTime: 2, // Porsi
      cookTime: 12, // Menit
    ),
    RecipeItem(
      name: 'Roti Panggang Blackberry', // Was: Fruity blackberry toast
      imageUrl: 'cookbooks/sandwich.jpg',
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

  BookmarkDetailScreen({Key? key, required this.category})
    : super(key: key);

  void handleBottomNavTap(int index) {
    // Handle navigation in a real app
    print('Navigated to index: $index');
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
        Container(
          margin: const EdgeInsets.only(right: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E0E0),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF8E1616)),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarkCreateScreen(savedRecipes: allSavedRecipes,),
                ),
              );
            },
          ),
        ),
      ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                category.name,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Recipe grid
            Expanded(
              child:
                  category.recipes.isEmpty
                      ? Center(
                        child: Text(
                          'Tidak ada resep dalam kategori ini',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: (category.recipes.length / 2).ceil(),
                        itemBuilder: (context, rowIndex) {
                          final int startIdx = rowIndex * 2;
                          return Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: RecipeCard(
                                    recipe: category.recipes[startIdx],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child:
                                    startIdx + 1 < category.recipes.length
                                        ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16.0,
                                          ),
                                          child: RecipeCard(
                                            recipe:
                                                category.recipes[startIdx + 1],
                                          ),
                                        )
                                        : const SizedBox(),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // REMOVED Edit button Container
          // Navigation bar with integrated FAB
          BottomNavBar(
            currentIndex: 1, // 1 for bookmark screen
            onTap: handleBottomNavTap,
            onFabPressed: () {
              // Handle FAB pressed action
              print('FAB pressed on BookmarkDetailScreen');
            },
          ),
        ],
      ),
    );
  }
}

// ... RecipeCard class remains the same ...
class RecipeCard extends StatelessWidget {
  final RecipeItem recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Recipe image
          AspectRatio(
            aspectRatio: 0.8,
            child: Image.asset(
              'assets/images/cookbooks/placeholder_image.jpg', // Use recipe.imageUrl if available
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          // Bookmark icon with blur background
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
                  child: const BookmarkSolid( // Assuming this is always bookmarked in detail view
                    width: 18,
                    height: 18,
                    color: Colors.white,
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
                  overflow: TextOverflow.ellipsis, // Added overflow handling
                ),
                const SizedBox(height: 8),
                // Recipe info with dividers
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible( // Use Flexible to prevent overflow
                      child: Text(
                        '${recipe.calories} Kalori',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, // Slightly smaller font
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      ' | ',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    Flexible(
                      child: Text(
                        '${recipe.prepTime} Porsi', // Assuming prepTime is Porsi
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      ' | ',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    Flexible(
                      child: Text(
                        '${recipe.cookTime} Menit',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}