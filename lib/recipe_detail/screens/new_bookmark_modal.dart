import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NewBookmarkModal extends StatefulWidget {
  final Function(String) onSave;
  
  const NewBookmarkModal({
    super.key,
    required this.onSave,
  });

  @override
  State<NewBookmarkModal> createState() => _NewBookmarkModalState();
}

class _NewBookmarkModalState extends State<NewBookmarkModal> {
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          const Text(
            "Buat Buku Resep Baru",
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 8),
          const Text(
            "buat buku resep baru untuk menyimpan resep Anda",
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          
          // Name input
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Nama Buku Resep",
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      widget.onSave(name);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Buat"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}