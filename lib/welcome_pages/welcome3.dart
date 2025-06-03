import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package

class Welcome3Screen extends StatelessWidget {
  const Welcome3Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    final double screenWidth = MediaQuery.of(context).size.width; // Dapatkan lebar layar

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: primaryRed, // Red background color
        ),
        child: Stack(
          children: [
            // Background food image
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_welcome3.png', // Placeholder for the food image
                fit: BoxFit.cover,
              ),
            ),

            // Enhanced gradient overlay from bottom to top for text visibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.8), // Stronger shadow at bottom
                      Colors.black.withOpacity(0.6), // Strong shadow
                      Colors.black.withOpacity(0.4), // Medium shadow
                      Colors.black.withOpacity(0.2), // Light shadow
                      Colors.transparent, // Fade to transparent
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
                      const Spacer(flex: 5), // Push content to bottom

                      // Main heading
                      Text(
                        'Dari Dapur\nke Dunia',
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
                        'Tunjukkan kreasi masakanmu dan lihat apa yang sedang dimasak oleh pengguna lain di seluruh Indonesia.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 40),

                      // Linear Progress Indicator with responsive width, centered
                      Center(
                        child: SizedBox(
                          width: screenWidth / 3, // Sepertiga dari lebar layar
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 1.00, // Adjust this value as needed (1/3 for first screen)
                              backgroundColor: primaryRed.withOpacity(0.32),
                              valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                              minHeight: 6,
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
    );
  }
}