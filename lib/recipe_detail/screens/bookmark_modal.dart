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

  @override
  void initState() {
    super.initState();
    _loadBookmarkFolders();
  }

  Future<void> _loadBookmarkFolders() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final folderData = await _bookmarkService.getBookmarkFolders();
      setState(() {
        folders = folderData;
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
          const Text(
            "tambahkan resep ini ke buku resep Anda",
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // Show loading, error, or folder list
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
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
                      onPressed: _loadBookmarkFolders,
                      child: const Text('Retry'),
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
            // Folder list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final folderId = folder['id'].toString();

                  // Create Cookbook object from folder data for compatibility with CookbookItem
                  final cookbook = Cookbook(
                    id: folderId,
                    name: folder['name'] ?? 'Unnamed Folder',
                    imageUrl:
                        folder['image_url'] ??
                        'assets/images/cookbooks/placeholder_image.jpg',
                    recipeCount: 0, // We could fetch this separately if needed
                  );

                  return CookbookItem(
                    cookbook: cookbook,
                    isSelected: selectedCookbookId == folderId,
                    onTap: () {
                      setState(() {
                        selectedCookbookId = folderId;
                      });
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
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
                                    content: Text('Error creating folder: $e'),
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
      ),
    );
  }
}
