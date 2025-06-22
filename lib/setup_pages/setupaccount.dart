import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'finishsetup.dart';
import 'setupdiets.dart';
import '../services/image_upload_service.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../services/supabase_client.dart'; // Import Supabase client

class SetupAccountPage extends StatefulWidget {
  final double startProgressValue;
  
  const SetupAccountPage({
    Key? key, 
    this.startProgressValue = 0.6,
  }) : super(key: key);

  @override
  State<SetupAccountPage> createState() => _SetupAccountPageState();
}

class _SetupAccountPageState extends State<SetupAccountPage> with SingleTickerProviderStateMixin {
  final Color primaryRed = const Color(0xFF8E1616);
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Image file variables
  File? _coverImage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  // Cloudinary integration
  final ImageUploadService _imageUploadService = ImageUploadService();
  String? _coverImageUrl;
  String? _profileImageUrl;
  bool _isUploadingCover = false;
  bool _isUploadingProfile = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: widget.startProgressValue,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      )
    );
    
    _progressController.forward();
  }
  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }
    // Function to pick cover image - dipilih saja, tidak langsung upload
  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 500,
      );
      
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
          // Tidak upload ke Cloudinary di sini
        });
        
        print("Cover image selected: ${pickedFile.path}");
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }
  // Function to pick profile image - dipilih saja, tidak langsung upload
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 400,
        maxHeight: 400,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          // Tidak upload ke Cloudinary di sini
        });
        
        print("Profile image selected: ${pickedFile.path}");
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }
  
  void _navigateBackToDiets() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => SetupDietsPage(
          startProgressValue: 0.3,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative lines
          Positioned.fill(
            child: Image.asset(
              'assets/images/Ornament.png',
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Top row with back arrow, progress indicator, and skip button
                      Row(
                        children: [
                          // Back arrow in red circle
                          GestureDetector(
                            onTap: _navigateBackToDiets,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Animated progress indicator
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _progressAnimation.value,
                                    backgroundColor: Colors.grey.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                                    minHeight: 6,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Skip button
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1, animation2) => 
                                    const FinishSetupScreen(),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Lewati',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Main content area with scrolling
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),

                          // Heading
                          Text(
                            'Atur akun\nAnda',
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Header photo upload area with Cloudinary upload indicator
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _isUploadingCover ? null : _pickCoverImage,
                                child: Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: _coverImage == null 
                                        ? primaryRed.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _isUploadingCover 
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const CircularProgressIndicator(),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Mengunggah ke Cloud...',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _coverImage == null 
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.image,
                                                  size: 32,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Unggah Foto Sampul',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                Text(
                                                  'Rekomendasi Ukuran: 1200 x 400',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            )                                          : Image.file(
                                              _coverImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Profile photo upload area with Cloudinary upload indicator
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Center(
                                child: GestureDetector(
                                  onTap: _isUploadingProfile ? null : _pickProfileImage,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: _profileImage == null
                                          ? primaryRed.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _isUploadingProfile
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const CircularProgressIndicator(),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Mengunggah...',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : _profileImage == null
                                            ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.camera_alt,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Unggah Foto',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              )                                            : Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32), // Add some space before the divider                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Continue button - updated to pass Cloudinary URLs
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, left: 24.0, right: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(                      onPressed: (_isUploadingCover || _isUploadingProfile) 
                          ? null 
                          : () async {
                              // Mulai proses upload
                              setState(() {
                                if (_coverImage != null) _isUploadingCover = true;
                                if (_profileImage != null) _isUploadingProfile = true;
                              });
                              
                              try {
                                // Upload foto sampul ke Cloudinary jika ada
                                if (_coverImage != null) {
                                  final coverUrl = await _imageUploadService.uploadImage(_coverImage!);
                                  if (coverUrl != null) {
                                    setState(() {
                                      _coverImageUrl = coverUrl;
                                    });
                                    print("Cover image uploaded successfully: $_coverImageUrl");
                                  }
                                }
                                
                                // Upload foto profil ke Cloudinary jika ada
                                if (_profileImage != null) {
                                  final profileUrl = await _imageUploadService.uploadImage(_profileImage!);
                                  if (profileUrl != null) {
                                    setState(() {
                                      _profileImageUrl = profileUrl;
                                    });
                                    print("Profile image uploaded successfully: $_profileImageUrl");
                                  }
                                }
                                
                                // Simpan URL ke Supabase jika salah satu foto berhasil diupload
                                final userId = AuthService.getCurrentUserId();
                                if (userId != null && (_coverImageUrl != null || _profileImageUrl != null)) {
                                  // Siapkan data untuk update
                                  final dataToUpdate = <String, dynamic>{};
                                  
                                  if (_coverImageUrl != null) {
                                    dataToUpdate['cover_picture'] = _coverImageUrl;
                                  }
                                  
                                  if (_profileImageUrl != null) {
                                    dataToUpdate['profile_picture'] = _profileImageUrl;
                                  }                                    // Update data user di Supabase
                                    if (dataToUpdate.isNotEmpty) {
                                      final supabase = SupabaseClientWrapper().client;
                                      await supabase
                                          .from('users')
                                          .update(dataToUpdate)
                                          .eq('id', userId);
                                          
                                      print("Data user berhasil diupdate di Supabase");
                                    }
                                }
                                
                                // Navigate to next screen
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation1, animation2) => 
                                        const FinishSetupScreen(),
                                      transitionDuration: const Duration(milliseconds: 300),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;
                                        
                                        var tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: curve));
                                        var offsetAnimation = animation.drive(tween);
                                        
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                }
                              } catch (e) {
                                print("Error saat upload/update: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Terjadi kesalahan: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isUploadingCover = false;
                                    _isUploadingProfile = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryRed.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isUploadingCover || _isUploadingProfile
                            ? 'Mengunggah...'
                            : 'Lanjut',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
