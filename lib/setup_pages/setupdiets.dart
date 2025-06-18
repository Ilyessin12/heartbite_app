import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'setupaccount.dart'; // Import SetupAccountPage
import 'setupallergies.dart'; // Import SetupAllergiesPage

class SetupDietsPage extends StatefulWidget {
  // Add parameter for the starting progress value
  final double startProgressValue;
  
  const SetupDietsPage({
    Key? key, 
    this.startProgressValue = 0.3, // Default to 0.3 if not provided
  }) : super(key: key);

  @override
  State<SetupDietsPage> createState() => _SetupDietsPageState();
}

class _SetupDietsPageState extends State<SetupDietsPage> with SingleTickerProviderStateMixin {
  final Color primaryRed = const Color(0xFF8E1616);
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Track selected diets
  final Set<String> selectedDiets = {}; // Changed from {'Vegetarian'} to empty set

  final List<String> diets = [
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Intermittent Fasting',
    'Atkins',
    'Dukan',
  ];

  @override
  void initState() {
    super.initState();
    // Set up animation controller for the progress bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: widget.startProgressValue,
      end: 0.6, // Target progress value for this page
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      )
    );
    
    // Start the animation when the widget is built
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // Function to navigate back to allergies page
  void _navigateBackToAllergies() {
    // Navigate to SetupAllergiesPage without animation
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const SetupAllergiesPage(),
        transitionDuration: Duration.zero, // No animation
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Top row with back arrow, progress indicator, and skip button
                  Row(
                    children: [
                      // Back arrow in red circle - Now with updated navigation
                      GestureDetector(
                        onTap: _navigateBackToAllergies, // Use the new navigation function
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
                          // Navigate to SetupAccountPage without animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupAccountPage(
                                startProgressValue: _progressAnimation.value,
                              ),
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

                  const SizedBox(height: 40),

                  // Heading
                  Text(
                    'Ada pola makan\ntertentu yang kamu ikuti?',
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Diets wrap
                  Expanded(
                    child: Wrap(
                      spacing: 12, // Jarak horizontal antar box
                      runSpacing: 12, // Jarak vertikal antar baris
                      alignment: WrapAlignment.start, // Rata kiri seperti grid sebelumnya
                      children: diets.map((diet) {
                        final isSelected = selectedDiets.contains(diet);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedDiets.remove(diet);
                              } else {
                                selectedDiets.add(diet);
                              }
                            });
                          },
                          child: IntrinsicWidth(
                            child: Container(
                              height: 40, // Tinggi seragam untuk semua box
                              padding: const EdgeInsets.symmetric(horizontal: 16), // Padding dalam box
                              decoration: BoxDecoration(
                                color: isSelected ? primaryRed : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  diet,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to SetupAccountPage with animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupAccountPage(
                                startProgressValue: _progressAnimation.value, // Pass current progress value
                              ),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
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
          ),
        ],
      ),
    );
  }
}