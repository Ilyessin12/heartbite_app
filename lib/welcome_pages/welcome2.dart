import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome1.dart'; // Import for type reference
import 'welcome3.dart'; // Import Welcome3Screen

class Welcome2Screen extends StatelessWidget {
  const Welcome2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    final double screenWidth = MediaQuery.of(context).size.width;

    // Function to navigate to Welcome3Screen with animation
    void navigateToWelcome3() {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const Welcome3Screen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        // Handle taps anywhere
        onTapUp: (TapUpDetails details) {
          // Check which half of the screen was tapped
          if (details.globalPosition.dx < screenWidth / 2) {
            // Left side - go back
            Navigator.of(context).pop();
          } else {
            // Right side - go forward
            navigateToWelcome3();
          }
        },
        
        // Handle swipes
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              // Right swipe detected (positive velocity) - go back
              Navigator.of(context).pop();
            } else if (details.primaryVelocity! < 0) {
              // Left swipe detected (negative velocity) - go forward
              navigateToWelcome3();
            }
          }
        },
        
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: primaryRed,
          ),
          child: Stack(
            children: [
              // Background food image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_welcome2.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Enhanced gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Content container
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(flex: 5),

                        // Main heading
                        Text(
                          'Bagikan Resep\nAndalanmu',
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subheading text
                        Text(
                          'Temukan inspirasi baru dan bagikan resep favoritmu dengan komunitas pecinta masak lainnya.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 64),


                        const SizedBox(height: 20),

                        // Linear Progress Indicator with animation
                        Center(
                          child: SizedBox(
                            width: screenWidth / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.33, end: 0.66),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: primaryRed.withOpacity(0.32),
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                                    minHeight: 6,
                                  );
                                }
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}