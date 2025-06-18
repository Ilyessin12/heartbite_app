import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'welcome1.dart'; // Import Welcome1Screen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Warna latar paling bawah
          Container(
            color: const Color(0xFF8E1616),
          ),

          // Gambar background di atas warna
          Positioned.fill(
            child: Opacity(opacity: 0.3, // Atur opacity sesuai kebutuhan
              child: Image.asset(
                'assets/images/bg_welcome.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Konten utama di atas semuanya
          SafeArea(
            child: SizedBox.expand( // pastikan Column mengisi seluruh layar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_heartBite.png',
                        width: 1000,
                        height: 1000,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nama aplikasi dengan DM Sans font
                  Text(
                    'HeartBite',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Tombol Mulai
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, left: 40, right: 40),
                    child: SizedBox(
                      width: size.width * 0.6,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Welcome1Screen instead of popping
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const Welcome1Screen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Mulai',
                          style: TextStyle(
                            fontSize: 18,
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
