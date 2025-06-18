import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'finishsetup.dart';
import 'setupdiets.dart';

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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Image file variables
  File? _coverImage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
    _usernameController.dispose();
    _displayNameController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  // Function to pick cover image
  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Adjust quality as needed
        maxWidth: 1500, // Updated from 1200 to 1500
        maxHeight: 500, // Updated from 400 to 500
      );
      
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  // Function to pick profile image
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
        });
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

                          // Header photo upload area - Now with image picker functionality
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Foto Sampul',
                              //   style: GoogleFonts.dmSans(
                              //     fontSize: 16,
                              //     fontWeight: FontWeight.w500,
                              //   ),
                              // ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickCoverImage,
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
                                  clipBehavior: Clip.antiAlias, // Ensure image stays within border radius
                                  child: _coverImage == null 
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
                                        )
                                      : Image.file(
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

                          // Profile photo upload area - Now with square shape
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Foto Profil',
                              //   style: GoogleFonts.dmSans(
                              //     fontSize: 16,
                              //     fontWeight: FontWeight.w500,
                              //   ),
                              // ),
                              const SizedBox(height: 8),
                              Center(
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: _profileImage == null
                                          ? primaryRed.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8), // Square with slightly rounded corners
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias, // Ensure image stays within border radius
                                    child: _profileImage == null
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
                                          )
                                        : Image.file(
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

                          const SizedBox(height: 32), // Add some space before the divider

                          // Fading horizontal divider
                          Container(
                            height: 1.0,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24.0), // Space after divider
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.grey.withOpacity(0.5),
                                  Colors.grey.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.1, 0.9, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),

                          // Display Name field with matching border color
                          TextField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Tampilan',
                              labelStyle: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              hintText: 'Nama yang ditampilkan ke pengguna lain',
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                              filled: true,
                              fillColor: primaryRed.withOpacity(0.12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: primaryRed.withOpacity(0.12), // Match with fillColor
                                ),
                              ),
                              enabledBorder: OutlineInputBorder( // Add this to control the default border
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: primaryRed.withOpacity(0.12), // Match with fillColor
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primaryRed), // Keep this as is for focus state
                              ),
                            ),
                            style: GoogleFonts.dmSans(fontSize: 16),
                          ),

                          const SizedBox(height: 16), // Add spacing between the fields

                          // Username field with @ prefix and matching border color
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              hintText: 'Username harus unik dan tidak sama dengan user lain',
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Text(
                                  '@',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              filled: true,
                              fillColor: primaryRed.withOpacity(0.12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: primaryRed.withOpacity(0.12), // Match with fillColor
                                ),
                              ),
                              enabledBorder: OutlineInputBorder( // Add this to control the default border
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: primaryRed.withOpacity(0.12), // Match with fillColor
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primaryRed), // Keep this as is for focus state
                              ),
                            ),
                            style: GoogleFonts.dmSans(fontSize: 16),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Continue button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, left: 24.0, right: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_usernameController.text.isNotEmpty) {
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
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a username')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Lanjut',
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
