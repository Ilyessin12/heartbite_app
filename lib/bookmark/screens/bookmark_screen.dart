import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import '../../services/bookmark_service.dart';
import '../../recipe/create_recipe_screen.dart';
import 'bookmark_detail_screen.dart';
import 'bookmark_create_screen.dart';
import 'bookmark_edit_screen.dart';
import '../models/bookmark_category.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  Set<int> selectedCategories = {};
  void toggleCategorySelection(int folderId) {
    setState(() {
      if (selectedCategories.contains(folderId)) {
        selectedCategories.remove(folderId);
      } else {
        selectedCategories.add(folderId);
      }
    });
  }

  Future<void> deleteSelectedCategories() async {
    try {
      await _bookmarkService.deleteBookmarkFolders(selectedCategories.toList());
      setState(() {
        selectedCategories.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected folders deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting folders: $e')));
    }
  }

  void handleBottomNavTap(int index) {
    if (index == 0) {
      // Navigate to Homepage using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        ModalRoute.withName('/'),
      );
    }
    // index == 1 is already bookmark screen, so no action needed
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
                        builder: (context) => const BookmarkCreateScreen(),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _bookmarkService.getBookmarkFolders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading bookmarks: ${snapshot.error}',
                  style: GoogleFonts.dmSans(color: Colors.red),
                ),
              );
            }

            final folders = snapshot.data ?? [];

            if (folders.isEmpty) {
              return Center(
                child: Text(
                  'No bookmark folders found',
                  style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                final category = BookmarkCategory.fromJson(folder);
                final isSavedCategory = category.name == 'Saved';
                final folderId = folder['id'];

                return GestureDetector(
                  onTap: () {
                    if (selectedCategories.isNotEmpty) {
                      if (!isSavedCategory) {
                        toggleCategorySelection(folderId);
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  BookmarkDetailScreen(category: category),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    if (!isSavedCategory) {
                      toggleCategorySelection(folderId);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        category.imageUrl.isNotEmpty &&
                                !category.imageUrl.startsWith('assets/')
                            ? Image.network(
                              category.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/cookbooks/placeholder_image.jpg',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                            : Image.asset(
                              category.imageUrl.isNotEmpty
                                  ? category.imageUrl
                                  : 'assets/images/cookbooks/placeholder_image.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
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
                        if (selectedCategories.contains(folderId))
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
            onFabPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRecipeScreen(),
                ),
              );
              if (result == true) {
                // Refresh bookmarks if needed
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }
}
