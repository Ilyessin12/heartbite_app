import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/cloudinary_service.dart';
import '../services/image_service.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenWithBackendState();
}

class _EditProfileScreenWithBackendState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingProfile = false;
  bool _isUploadingCover = false;
  
  String? _newProfileImageUrl;
  String? _newCoverImageUrl;
  Uint8List? _selectedProfileImageBytes;
  Uint8List? _selectedCoverImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await ProfileService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.fullName;
          _usernameController.text = user.username;
          _emailController.text = user.email;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data profil');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    try {
      final imageBytes = await ImageService.pickImageAsBytes(source);
      
      if (imageBytes != null) {
        if (isProfileImage) {
          setState(() {
            _selectedProfileImageBytes = imageBytes;
          });
          await _uploadProfileImage(imageBytes);
        } else {
          setState(() {
            _selectedCoverImageBytes = imageBytes;
          });
          await _uploadCoverImage(imageBytes);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar');
    }
  }

  Future<void> _uploadProfileImage(Uint8List imageBytes) async {
    setState(() => _isUploadingProfile = true);
    
    try {
      final fileName = ImageService.generateFileName('profile');
      final extension = ImageService.getFileExtension(imageBytes);
      
      final imageUrl = await CloudinaryService.uploadImageFromBytes(
        imageBytes,
        '$fileName.$extension',
        folder: 'heartbite/profiles',
      );
      
      if (imageUrl != null) {
        setState(() {
          _newProfileImageUrl = imageUrl;
        });
        _showSuccessSnackBar('Foto profil berhasil diupload');
      } else {
        _showErrorSnackBar('Gagal mengupload foto profil');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengupload foto profil');
    } finally {
      setState(() => _isUploadingProfile = false);
    }
  }

  Future<void> _uploadCoverImage(Uint8List imageBytes) async {
    setState(() => _isUploadingCover = true);
    
    try {
      final fileName = ImageService.generateFileName('cover');
      final extension = ImageService.getFileExtension(imageBytes);
      
      final imageUrl = await CloudinaryService.uploadImageFromBytes(
        imageBytes,
        '$fileName.$extension',
        folder: 'heartbite/covers',
      );
      
      if (imageUrl != null) {
        setState(() {
          _newCoverImageUrl = imageUrl;
        });
        _showSuccessSnackBar('Foto sampul berhasil diupload');
      } else {
        _showErrorSnackBar('Gagal mengupload foto sampul');
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengupload foto sampul');
    } finally {
      setState(() => _isUploadingCover = false);
    }
  }

  void _showImageSourceDialog(bool isProfileImage) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!kIsWeb) // Hide camera option on web
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isProfileImage);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isProfileImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        _showErrorSnackBar('User tidak ditemukan');
        return;
      }

      // Check username availability if changed
      if (_usernameController.text != _currentUser!.username) {
        final isAvailable = await ProfileService.isUsernameAvailable(
          _usernameController.text,
          userId,
        );
        
        if (!isAvailable) {
          _showErrorSnackBar('Username sudah digunakan');
          return;
        }
      }

      // Prepare update data
      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Add image URLs if uploaded
      if (_newProfileImageUrl != null) {
        updates['profile_picture'] = _newProfileImageUrl;
      }
      
      if (_newCoverImageUrl != null) {
        updates['cover_picture'] = _newCoverImageUrl;
      }

      // Update profile
      final success = await ProfileService.updateUserProfile(userId, updates);
      
      if (success) {
        _showSuccessSnackBar('Profil berhasil diperbarui');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Gagal memperbarui profil');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan saat menyimpan');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Gagal memuat data profil'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(context),
              _buildProfilePicture(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        'Nama Lengkap',
                        _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'Username',
                        _usernameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          if (value.trim().length < 3) {
                            return 'Username minimal 3 karakter';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                            return 'Username hanya boleh huruf, angka, dan underscore';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'Email',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
  return Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          // Background/Cover Photo
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
            ),
            child: _buildCoverImage(),
          ),
          
          // Cover photo edit button
          Positioned(
            top: 12,
            right: 12,
            child: ElevatedButton(
              onPressed: () => _showImageSourceDialog(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              child: _isUploadingCover
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
          
          // Profile Picture
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: _buildProfileImage(),
                    ),
                  ),
                  
                  // Profile picture edit button dengan ElevatedButton
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: ElevatedButton(
                      onPressed: () {
                        print("Profile picture edit button pressed!"); // Debug
                        _showImageSourceDialog(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        elevation: 4,
                      ),
                      child: _isUploadingProfile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 48),
    ],
  );
}

  // widget background kosong
  // Widget _buildCoverImage() {
  //   if (_selectedCoverImageBytes != null) {
  //     return Image.memory(
  //       _selectedCoverImageBytes!,
  //       fit: BoxFit.cover,
  //     );
  //   } else if (_newCoverImageUrl != null) {
  //     return Image.network(
  //       _newCoverImageUrl!,
  //       fit: BoxFit.cover,
  //     );
  //   } else if (_currentUser!.coverPicture != null) {
  //     return Image.network(
  //       _currentUser!.coverPicture!,
  //       fit: BoxFit.cover,
  //     );
  //   } else {
  //     return Container(
  //       color: Colors.grey[300],
  //       child: const Icon(
  //         Icons.image,
  //         size: 50,
  //         color: Colors.grey,
  //       ),
  //     );
  //   }
  // }

  // widget background default
  Widget _buildCoverImage() {
    if (_selectedCoverImageBytes != null) {
      return Image.memory(
        _selectedCoverImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (_newCoverImageUrl != null && _newCoverImageUrl!.isNotEmpty) {
      return Image.network(
        _newCoverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/bg_welcome.png',
            fit: BoxFit.cover,
          );
        },
      );
    } else if (_currentUser?.coverPicture != null && _currentUser!.coverPicture!.isNotEmpty) {
      return Image.network(
        _currentUser!.coverPicture!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/bg_welcome.png',
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        'assets/images/bg_welcome.png',
        fit: BoxFit.cover,
      );
    }
  }


  Widget _buildProfileImage() {
    if (_selectedProfileImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _selectedProfileImageBytes!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else if (_newProfileImageUrl != null) {
      return ClipOval(
        child: Image.network(
          _newProfileImageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else if (_currentUser!.profilePicture != null) {
      return ClipOval(
        child: Image.network(
          _currentUser!.profilePicture!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Text(
        _currentUser!.fullName.isNotEmpty
            ? _currentUser!.fullName[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.grayLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(left: 160.0),
                      child: Text('Simpan'),
                    ),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
