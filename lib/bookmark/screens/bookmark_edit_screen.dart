import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../bottomnavbar/bottom-navbar.dart';
import '../../services/bookmark_service.dart';
import '../../services/image_upload_service.dart';
import '../../recipe/create_recipe_screen.dart';
import '../models/bookmark_category.dart';

class BookmarkEditScreen extends StatefulWidget {
  final BookmarkCategory category;

  const BookmarkEditScreen({Key? key, required this.category})
    : super(key: key);

  @override
  State<BookmarkEditScreen> createState() => _BookmarkEditScreenState();
}

class _BookmarkEditScreenState extends State<BookmarkEditScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> saveChanges() async {
    if (widget.category.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid category ID')));
      return;
    }

    try {
      // Upload new image to Cloudinary if selected
      String? finalImageUrl = widget.category.imageUrl;
      if (_selectedImage != null) {
        finalImageUrl = await _imageUploadService.uploadImage(_selectedImage!);
        if (finalImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image upload failed. Please try again.'),
            ),
          );
          return;
        }
      }

      await _bookmarkService.updateBookmarkFolder(
        folderId: widget.category.id!,
        name: _nameController.text.trim(),
        imageUrl: finalImageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark folder updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating bookmark: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.dmSans()),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Camera', style: GoogleFonts.dmSans()),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1000,
                      maxHeight: 1000,
                      imageQuality: 85,
                    );

                    if (photo != null) {
                      setState(() {
                        _selectedImage = File(photo.path);
                      });
                    }
                  } catch (e) {
                    print('Error taking photo: $e');
                  }
                },
              ),
            ],
          ),
        );
      },
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Edit Bookmark',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child:
                          _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.cover)
                              : widget.category.imageUrl.isNotEmpty &&
                                  !widget.category.imageUrl.startsWith(
                                    'assets/',
                                  )
                              ? Image.network(
                                widget.category.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/default_food.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                              : Image.asset(
                                widget.category.imageUrl.isNotEmpty
                                    ? widget.category.imageUrl
                                    : 'assets/images/default_food.png',
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    child: Text(
                      'Change Cover',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: const Color(0xFF8E1616),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E0E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.dmSans(fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter bookmark name',
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E1616),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: handleBottomNavTap,
        onFabPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
          );
          if (result == true) {
            // Refresh if needed
          }
        },
      ),
    );
  }
}
