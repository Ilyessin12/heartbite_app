import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome2.dart'; // Import Welcome2Screen
import 'welcome.dart'; // Import WelcomeScreen for navigation

class Welcome1Screen extends StatelessWidget {
  const Welcome1Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    final double screenWidth = MediaQuery.of(context).size.width;

    // Function to navigate to Welcome2Screen with animation
    void navigateToWelcome2() {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const Welcome2Screen(),
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
    
    // Function to navigate back to WelcomeScreen with slide-right animation
    void navigateBackToWelcome() {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
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
        // Handle taps based on screen side
        onTapUp: (TapUpDetails details) {
          // If tap is on left side of the screen, go back
          if (details.globalPosition.dx < screenWidth / 2) {
            navigateBackToWelcome();
          } else {
            // If tap is on right side, go forward
            navigateToWelcome2();
          }
        },
        
        // Handle swipes in both directions
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < 0) {
              // Detect left swipe (negative velocity)
              navigateToWelcome2();
            } else if (details.primaryVelocity! > 0) {
              // Detect right swipe (positive velocity)
              navigateBackToWelcome();
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
                  'assets/images/bg_welcome1.png',
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
                          'Cari Resep Sesuai\nGaya Masakmu',
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
                          'Temukan resep yang cocok dengan\nalat masak yang kamu punya, preferensi diet, dan kebutuhan alergi.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 64),


                        const SizedBox(height: 20),

                        // Linear Progress Indicator
                        Center(
                          child: SizedBox(
                            width: screenWidth / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 0.33),
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