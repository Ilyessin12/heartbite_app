import 'package:flutter/material.dart';
import '../models/cookbook.dart';
import '../widgets/cookbook_item.dart';
import '../utils/constants.dart';
import 'new_bookmark_modal.dart';
import '../../services/bookmark_service.dart';

class BookmarkModal extends StatefulWidget {
  final Function(String) onSave;

  const BookmarkModal({super.key, required this.onSave});

  @override
  State<BookmarkModal> createState() => _BookmarkModalState();
}

class _BookmarkModalState extends State<BookmarkModal> {
  String? selectedCookbookId;
  final BookmarkService _bookmarkService = BookmarkService();
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;
  String? errorMessage;
  int? savedFolderId;
  bool hasCustomFolders = false;

  @override
  void initState() {
    super.initState();
    _initializeBookmarkState();
  }

  Future<void> _initializeBookmarkState() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Ensure "Saved" folder exists and get its ID
      savedFolderId = await _bookmarkService.ensureSavedFolderExists();

      // Check if user has custom folders
      hasCustomFolders = await _bookmarkService.hasCustomBookmarkFolders();

      if (hasCustomFolders) {
        // Load all folders if user has custom ones
        await _loadBookmarkFolders();
      } else {
        // Auto-save to "Saved" folder if no custom folders exist
        setState(() {
          isLoading = false;
          selectedCookbookId = savedFolderId.toString();
        });

        // Automatically save and close modal
        _autoSaveToSavedFolder();
      }
    } catch (e) {
      print('Error initializing bookmark state: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to initialize bookmark: $e';
      });
    }
  }

  Future<void> _autoSaveToSavedFolder() async {
    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && selectedCookbookId != null) {
      widget.onSave(selectedCookbookId!);
    }
  }

  Future<void> _loadBookmarkFolders() async {
    try {
      final folderData = await _bookmarkService.getBookmarkFolders();
      setState(() {
        folders = folderData;
        // Auto-select "Saved" folder by default
        selectedCookbookId = savedFolderId.toString();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading bookmark folders: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load bookmark folders: $e';
      });
    }
  }

  String _getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'assets/images/default_food.png';
    }

    // If it's already an asset path, return as is
    if (imageUrl.startsWith('assets/')) {
      return imageUrl;
    }

    // If it's a network URL, validate it
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it's neither asset nor valid URL, return placeholder
    return 'assets/images/default_food.png';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tambahkan ke Buku Resep", style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            hasCustomFolders
                ? "Pilih buku resep untuk menyimpan resep ini"
                : "Menyimpan ke 'Saved'...",
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // Show loading, error, or folder list
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      hasCustomFolders
                          ? "Loading folders..."
                          : "Saving to Saved...",
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _initializeBookmarkState,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (!hasCustomFolders)
            // Show simple saved message for auto-save case
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_added,
                      size: 48,
                      color: Color(0xFF8E1616),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Recipe saved to "Saved" folder!',
                      style: AppTextStyles.subheading,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (folders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No bookmark folders found. Create your first folder!',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            // Folder list (only shown when user has custom folders)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final folderId = folder['id'].toString();
                  final isDefaultFolder =
                      folder['is_default'] ==
                      true; // Create Cookbook object from folder data for compatibility with CookbookItem
                  final cookbook = Cookbook(
                    id: folderId,
                    name: folder['name'] ?? 'Unnamed Folder',
                    imageUrl: _getValidImageUrl(folder['image_url']),
                    recipeCount: 0, // We could fetch this separately if needed
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border:
                          isDefaultFolder
                              ? Border.all(
                                color: const Color(0xFF8E1616),
                                width: 2,
                              )
                              : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CookbookItem(
                      cookbook: cookbook,
                      isSelected: selectedCookbookId == folderId,
                      onTap: () {
                        setState(() {
                          selectedCookbookId = folderId;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          if (hasCustomFolders) ...[
            const SizedBox(height: 16),

            // Action buttons (only shown when user has custom folders)
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => NewBookmarkModal(
                            onSave: (name, imageUrl) async {
                              try {
                                final newFolder = await _bookmarkService
                                    .createBookmarkFolder(
                                      name: name,
                                      imageUrl: imageUrl,
                                    );
                                final folderId = newFolder['id'].toString();
                                widget.onSave(folderId);
                              } catch (e) {
                                print('Error creating bookmark folder: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error creating folder: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed:
                          selectedCookbookId != null
                              ? () => widget.onSave(selectedCookbookId!)
                              : null,
                      child: const Text("Simpan"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
