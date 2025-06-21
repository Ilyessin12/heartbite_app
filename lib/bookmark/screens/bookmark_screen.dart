import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import 'bookmark_detail_screen.dart';
import 'bookmark_create_screen.dart';
import 'bookmark_edit_screen.dart';
import '../models/bookmark_category.dart';
import '../models/recipe_item.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final List<RecipeItem> allSavedRecipes = [
    RecipeItem(
      name: 'Roti Panggang Blueberry',
      imageUrl: 'placeholder_image.jpg',
      rating: 4.8,
      reviewCount: 128,
      calories: 23,
      prepTime: 2,
      cookTime: 12,
    ),
    RecipeItem(
      name: 'Roti Panggang Blackberry',
      imageUrl: 'placeholder_image.jpg',
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

  late List<BookmarkCategory> categories;

  @override
  void initState() {
    super.initState();
    categories = [
      BookmarkCategory(
        name: 'Saved',
        imageUrl: 'placeholder_image.jpg',
        recipes: List.from(allSavedRecipes),
      ),
      BookmarkCategory(
        name: 'Resep Akhir Pekan',
        imageUrl: 'placeholder_image.jpg',
        recipes: [allSavedRecipes[0], allSavedRecipes[1]],
      ),
      BookmarkCategory(
        name: 'Makan Malam',
        imageUrl: 'placeholder_image.jpg',
        recipes: [allSavedRecipes[2], allSavedRecipes[3], allSavedRecipes[4]],
      ),
    ];
  }

  Set<int> selectedCategories = {};

  void toggleCategorySelection(int index) {
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
      final toDelete =
          selectedCategories.toList()..sort((a, b) => b.compareTo(a));

      for (final index in toDelete) {
        if (categories[index].name != 'Saved') {
          categories.removeAt(index);
        }
      }

      selectedCategories.clear();
    });
  }

  void handleBottomNavTap(int index) {
    print('Navigated to index: $index');
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _navigateToEdit(BookmarkCategory category) {
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
                  '${selectedCategories.length} item terpilih',
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
                        builder:
                            (context) => BookmarkCreateScreen(
                              savedRecipes: allSavedRecipes,
                            ),
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
                  if (!isSavedCategory) {
                    toggleCategorySelection(index);
                  }
                } else {
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
                if (!isSavedCategory) {
                  toggleCategorySelection(index);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/cookbooks/placeholder_image.jpg',
                      fit: BoxFit.cover,
                    ),
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
                    if (selectedCategories.contains(index))
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 24,
                            color: Color(0xFFAFF4C6),
                          ),
                        ),
                      ),
                    if (selectedCategories.isEmpty && !isSavedCategory)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _navigateToEdit(category),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              SolarIconsOutline.penNewSquare,
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
          BottomNavBar(
            currentIndex: 1,
            onTap: handleBottomNavTap,
            onFabPressed: () {
              print('FAB pressed on BookmarkScreen');
            },
          ),
        ],
      ),
    );
  }
}
