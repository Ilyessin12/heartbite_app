import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart'; // Pastikan package ini sudah diimpor
import '../bottomnavbar/bottom-navbar.dart'; // Sesuaikan path import sesuai struktur project Anda

class EmptyNotificationPage extends StatefulWidget {
  const EmptyNotificationPage({Key? key}) : super(key: key);

  @override
  State<EmptyNotificationPage> createState() => _EmptyNotificationPageState();
}

class _EmptyNotificationPageState extends State<EmptyNotificationPage> {
  int _currentIndex = 0; // Default index, bisa disesuaikan

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Navigasi ke halaman lain berdasarkan index yang dipilih
    // Ini hanya contoh, Anda perlu menyesuaikan dengan navigasi aplikasi Anda
    // if (index == 0) {
    //   // Navigasi ke Home
    // } else if (index == 1) {
    //   // Navigasi ke Bookmark
    // }
  }

  void _onFabPressed() {
    // Implementasi aksi ketika FAB ditekan
    // Misalnya membuka halaman tambah resep baru
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFF8E1616);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  // Back button in red circle
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
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title
                  Text(
                    'Notifikasi',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Empty space
            const Spacer(flex: 1),
            
            // Empty notification illustration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Image.asset(
                'assets/images/empty_notif_illustration.png', // Placeholder for the illustration
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // "No notifications yet" text
            Text(
              'Belum ada Notifikasi',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Empty space
            const Spacer(flex: 2),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        onFabPressed: _onFabPressed,
      ),
    );
  }
}