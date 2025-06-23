import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import '../../services/bookmark_service.dart';
import '../../recipe/create_recipe_screen.dart';
import '../models/bookmark_category.dart';
import '../models/recipe_item.dart';
import '../widgets/recipe_card.dart';
import 'bookmark_create_screen.dart';
import '../../recipe_detail/screens/recipe_detail_screen.dart';

class BookmarkDetailScreen extends StatefulWidget {
  final BookmarkCategory category;

  const BookmarkDetailScreen({Key? key, required this.category})
    : super(key: key);

  @override
  State<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends State<BookmarkDetailScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  Set<int> selectedRecipeIds = {};
  bool isSelectionMode = false;
  List<Map<String, dynamic>> bookmarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      if (widget.category.id != null) {
        final bookmarkData = await _bookmarkService.getBookmarksFromFolder(
          widget.category.id!,
        );
        if (mounted) {
          setState(() {
            bookmarks = bookmarkData;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memuat bookmark: $e')));
      }
    }
  }

  void _toggleSelectionMode() {
    if (!mounted) return;

    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedRecipeIds.clear();
    });
  }

  void _toggleRecipeSelection(int recipeId) {
    if (!mounted) return;

    setState(() {
      if (selectedRecipeIds.contains(recipeId)) {
        selectedRecipeIds.remove(recipeId);
      } else {
        selectedRecipeIds.add(recipeId);
      }
    });
  }

  Future<void> _removeSelectedRecipes() async {
    if (selectedRecipeIds.isEmpty || widget.category.id == null) return;

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Hapus Resep'),
              content: Text(
                widget.category.name == 'Saved'
                    ? 'Apakah Anda yakin ingin menghapus ${selectedRecipeIds.length} resep? Ini akan menghapusnya dari SEMUA folder.'
                    : 'Apakah Anda yakin ingin menghapus ${selectedRecipeIds.length} resep dari "${widget.category.name}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Hapus'),
                ),
              ],
            ),
      );
      if (confirmed == true) {
        // Use bulk removal for better performance
        await _bookmarkService.removeMultipleBookmarksFromFolder(
          recipeIds: selectedRecipeIds.toList(),
          folderId: widget.category.id!,
        );

        final removedCount = selectedRecipeIds.length;

        if (mounted) {
          setState(() {
            isSelectionMode = false;
            selectedRecipeIds.clear();
          });

          await _loadBookmarks(); // Refresh the list
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$removedCount resep berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus resep: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeRecipe(int recipeId) async {
    if (widget.category.id == null) return;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Hapus Resep'),
              content: Text(
                widget.category.name == 'Saved'
                    ? 'Apakah Anda yakin ingin menghapus resep ini? Ini akan menghapusnya dari SEMUA folder.'
                    : 'Apakah Anda yakin ingin menghapus resep ini dari "${widget.category.name}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Hapus'),
                ),
              ],
            ),
      );
      if (confirmed == true) {
        await _bookmarkService.removeBookmarkFromFolder(
          recipeId: recipeId,
          folderId: widget.category.id!,
        );

        if (mounted) {
          await _loadBookmarks(); // Refresh the list

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resep berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus resep: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void handleBottomNavTap(int index) {
    if (index == 0) {
      // Navigate to HomePage using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        ModalRoute.withName('/'),
      );
    } else if (index == 1) {
      // Navigate to main bookmark screen using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bookmark',
        ModalRoute.withName('/'),
      );
    }
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
          isSelectionMode ? '${selectedRecipeIds.length} terpilih' : 'Bookmark',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            isSelectionMode ? Icons.close : Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed:
              isSelectionMode
                  ? _toggleSelectionMode
                  : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isSelectionMode && selectedRecipeIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _removeSelectedRecipes,
            )
          else if (!isSelectionMode && bookmarks.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'select') {
                  _toggleSelectionMode();
                } else if (value == 'add') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookmarkCreateScreen(),
                    ),
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Pilih'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Tambahkan ke folder'),
                        ],
                      ),
                    ),
                  ],
            )
          else
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
                widget.category.name,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child:
                  widget.category.id == null
                      ? Center(
                        child: Text(
                          'ID kategori tidak valid',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      )
                      : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : bookmarks.isEmpty
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
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          final recipe = RecipeItem.fromJson(bookmark);
                          final isSelected = selectedRecipeIds.contains(
                            recipe.id,
                          );

                          return GestureDetector(
                            onTap: () {
                              if (isSelectionMode) {
                                if (recipe.id != null) {
                                  _toggleRecipeSelection(recipe.id!);
                                }
                              } else {
                                // Navigate to recipe detail
                                if (recipe.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RecipeDetailScreen(
                                            recipeId: recipe.id!,
                                          ),
                                    ),
                                  ).then(
                                    (_) => _loadBookmarks(),
                                  ); // Refresh when returning
                                }
                              }
                            },
                            onLongPress: () {
                              if (!isSelectionMode) {
                                _toggleSelectionMode();
                                if (recipe.id != null) {
                                  _toggleRecipeSelection(recipe.id!);
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                RecipeCard(
                                  recipe: recipe,
                                  showRemoveButton: !isSelectionMode,
                                  onRemove: () {
                                    if (recipe.id != null) {
                                      _removeRecipe(recipe.id!);
                                    }
                                  },
                                ),

                                // Selection overlay
                                if (isSelectionMode)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.black.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),

                                // Selection checkbox
                                if (isSelectionMode)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color:
                                            isSelected
                                                ? Colors.blue
                                                : Colors.grey,
                                      ),
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
                _loadBookmarks(); // Refresh bookmarks if needed
              }
            },
          ),
        ],
      ),
    );
  }
}
