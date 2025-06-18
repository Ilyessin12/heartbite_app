import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'setupdiets.dart'; // Import setupdiets.dart for navigation

class SetupAllergiesPage extends StatefulWidget {
  const SetupAllergiesPage({Key? key}) : super(key: key);

  @override
  State<SetupAllergiesPage> createState() => _SetupAllergiesPageState();
}

class _SetupAllergiesPageState extends State<SetupAllergiesPage> {
  final Color primaryRed = const Color(0xFF8E1616);

  // Track selected allergies - now empty by default
  final Set<String> selectedAllergies = {}; // Removed 'Ikan' pre-selection

  final List<String> allergies = [
    'Gluten', 'Produk Susu', 'Telur',
    'Kedelai', 'Kacang Tanah', 'Gandum',
    'Susu', 'Ikan'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative lines
          Positioned.fill(
            child: Image.asset(
              'assets/images/Ornament.png', // Placeholder for background pattern
              fit: BoxFit.contain, // Zoom out: seluruh gambar terlihat
              alignment: Alignment.topLeft, // Posisikan di kiri atas
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
                      // Back arrow in red circle
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryRed,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center, // Memusatkan anak (Icon)
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Colors.white, // Kontras dengan lingkaran merah
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Progress indicator
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.3, // Adjust as needed
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                            minHeight: 6,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Skip button - now with functionality
                      TextButton(
                        onPressed: () {
                          // Navigate to SetupDietsPage without animation
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupDietsPage(
                                startProgressValue: 0.3, // Pass the current progress value
                              ),
                              transitionDuration: Duration.zero, // No animation
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
                    'Apa kamu alergi terhadap sesuatu?',
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Allergies grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: allergies.map((allergy) {
                        final isSelected = selectedAllergies.contains(allergy);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedAllergies.remove(allergy);
                              } else {
                                selectedAllergies.add(allergy);
                              }
                            });
                          },
                          child: Container(
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
                                allergy,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.black,
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
                          // Navigate to diets page with our selected allergies
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) => SetupDietsPage(
                                startProgressValue: 0.3, // Pass the current progress value
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