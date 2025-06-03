import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetupDietsPage extends StatefulWidget {
  const SetupDietsPage({Key? key}) : super(key: key);

  @override
  State<SetupDietsPage> createState() => _SetupDietsPageState();
}

class _SetupDietsPageState extends State<SetupDietsPage> {
  final Color primaryRed = const Color(0xFF8E1616);

  // Track selected diets
  final Set<String> selectedDiets = {'Vegetarian'}; // Tidak ada diet yang dipilih secara default

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
                          alignment: Alignment.center, // Memusatkan ikon
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
                            value: 0.4, // Sesuaikan (misalnya, 0.4 untuk langkah berikutnya)
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                            minHeight: 6,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Skip button
                      TextButton(
                        onPressed: () {
                          // Handle skip action
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
                          // Handle continue action
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