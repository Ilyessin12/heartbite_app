import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart'
    hide Key, Text, List, Navigator;
import 'dart:ui';

import '../../bottomnavbar/bottom-navbar.dart';
import '../models/bookmark_category.dart';
import '../models/recipe_item.dart';
import '../widgets/recipe_card.dart';
import 'bookmark_create_screen.dart';

class BookmarkDetailScreen extends StatelessWidget {
  final BookmarkCategory category;
  final List<RecipeItem> allSavedRecipes = [
    RecipeItem(
      name: 'Roti Panggang Blueberry',
      imageUrl: 'cookbooks/sandwich.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 23,
      prepTime: 2,
      cookTime: 12,
    ),
    RecipeItem(
      name: 'Roti Panggang Blackberry',
      imageUrl: 'cookbooks/sandwich.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 24,
      prepTime: 2,
      cookTime: 12,
    ),
    RecipeItem(
      name: 'Nasi Goreng Spesial',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.5,
      reviewCount: 210,
      calories: 350,
      prepTime: 2,
      cookTime: 20,
    ),
    RecipeItem(
      name: 'Ayam Bakar Madu',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.9,
      reviewCount: 305,
      calories: 420,
      prepTime: 4,
      cookTime: 45,
    ),
    RecipeItem(
      name: 'Sate Ayam Bumbu Kacang',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.7,
      reviewCount: 180,
      calories: 380,
      prepTime: 3,
      cookTime: 30,
    ),
  ];

  BookmarkDetailScreen({Key? key, required this.category}) : super(key: key);

  void handleBottomNavTap(int index) {
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BookmarkCreateScreen(savedRecipes: allSavedRecipes),
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
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: category.recipes.length,
                          itemBuilder: (context, index){
                            return RecipeCard(
                              recipe: category.recipes[index],
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
          BottomNavBar(
            currentIndex: 1,
            onTap: handleBottomNavTap,
            onFabPressed: () {
              print('FAB pressed on BookmarkDetailScreen');
            },
          ),
        ],
      ),
    );
  }
}
