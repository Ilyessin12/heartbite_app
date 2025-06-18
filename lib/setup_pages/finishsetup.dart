import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../homepage/homepage.dart'; // Import HomePage

class FinishSetupScreen extends StatelessWidget {
  const FinishSetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
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
                        'Pengaturan Akun\nSelesai',
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
                        'Ayo mulai temukan resep terbaik dan sesuaikan dengan preferensimu!',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 40),

                      // Button to navigate to HomePage
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to the HomePage and remove all previous routes
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                                (route) => false, // This removes all previous routes
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed, // Changed from white to primaryRed
                              foregroundColor: Colors.white, // Changed from primaryRed to white
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Mulai Sekarang',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
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