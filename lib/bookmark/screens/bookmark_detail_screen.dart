import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import '../../services/bookmark_service.dart';
import '../models/bookmark_category.dart';
import '../models/recipe_item.dart';
import '../widgets/recipe_card.dart';
import 'bookmark_create_screen.dart';

class BookmarkDetailScreen extends StatelessWidget {
  final BookmarkCategory category;
  final BookmarkService _bookmarkService = BookmarkService();

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
                    builder: (context) => const BookmarkCreateScreen(),
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
                  category.id == null
                      ? Center(
                        child: Text(
                          'Invalid category ID',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _bookmarkService.getBookmarksFromFolder(
                          category.id!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading recipes: ${snapshot.error}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }

                          final bookmarks =
                              snapshot.data ?? <Map<String, dynamic>>[];

                          if (bookmarks.isEmpty) {
                            return Center(
                              child: Text(
                                'Tidak ada resep dalam kategori ini',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.7,
                                ),
                            itemCount: bookmarks.length,
                            itemBuilder: (context, index) {
                              final bookmark = bookmarks[index];
                              final recipe = RecipeItem.fromJson(bookmark);
                              return RecipeCard(recipe: recipe);
                            },
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
