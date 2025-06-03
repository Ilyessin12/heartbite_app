import 'package:flutter/material.dart';
import '../models/cookbook.dart';
import '../widgets/cookbook_item.dart';
import '../utils/constants.dart';
import 'new_bookmark_modal.dart';

class BookmarkModal extends StatefulWidget {
  final Function(String) onSave;
  
  const BookmarkModal({
    super.key,
    required this.onSave,
  });

  @override
  State<BookmarkModal> createState() => _BookmarkModalState();
}

class _BookmarkModalState extends State<BookmarkModal> {
  String? selectedCookbookId;
  
  // Sample cookbooks data
  final List<Cookbook> cookbooks = [
    Cookbook(
      id: '1',
      name: 'Kue Lezat',
      imageUrl: 'assets/images/cookbooks/cake.jpg',
      recipeCount: 23,
    ),
    Cookbook(
      id: '2',
      name: 'Masakan Ayam',
      imageUrl: 'assets/images/cookbooks/chicken.jpg',
      recipeCount: 12,
    ),
  ];
  
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
          const Text(
            "Tambahkan ke Buku Resep",
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 8),
          const Text(
            "tambahkan resep ini ke buku resep Anda",
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          
          // Cookbook list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cookbooks.length,
            itemBuilder: (context, index) {
              final cookbook = cookbooks[index];
              return CookbookItem(
                cookbook: cookbook,
                isSelected: selectedCookbookId == cookbook.id,
                onTap: () {
                  setState(() {
                    selectedCookbookId = cookbook.id;
                  });
                },
              );
            },
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
                    builder: (context) => NewBookmarkModal(
                      onSave: (name) {
                        // Create new cookbook and select it
                        final newId = DateTime.now().millisecondsSinceEpoch.toString();
                        setState(() {
                          cookbooks.add(
                            Cookbook(
                              id: newId,
                              name: name,
                              imageUrl: 'assets/images/cookbooks/cake.jpg', // Default image
                              recipeCount: 1,
                            ),
                          );
                          selectedCookbookId = newId;
                        });
                        widget.onSave(newId);
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
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: selectedCookbookId != null
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