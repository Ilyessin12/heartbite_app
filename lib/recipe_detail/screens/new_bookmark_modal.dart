import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../../services/image_upload_service.dart';

class NewBookmarkModal extends StatefulWidget {
  final Function(String, String?)
  onSave; // Updated to include imageUrl parameter

  const NewBookmarkModal({super.key, required this.onSave});

  @override
  State<NewBookmarkModal> createState() => _NewBookmarkModalState();
}

class _NewBookmarkModalState extends State<NewBookmarkModal> {
  final TextEditingController _nameController = TextEditingController();
  final ImageUploadService _imageUploadService = ImageUploadService();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createFolder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _imageUploadService.uploadImage(_selectedImage!);
      }

      widget.onSave(name, imageUrl);
      Navigator.pop(context);
    } catch (e) {
      print('Error creating folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
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
          const Text("Buat Buku Resep Baru", style: AppTextStyles.heading),
          const SizedBox(height: 8),
          const Text(
            "buat buku resep baru untuk menyimpan resep Anda",
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child:
                  _selectedImage != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.grey,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap to add cover image (optional)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
            ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _createFolder,
                  child:
                      _isUploading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text("Buat"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
