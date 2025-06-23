import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../../services/auth_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat datang di HeartBite!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HeartBite adalah aplikasi berbagi resep masakan yang dirancang untuk para pecinta kuliner. Temukan berbagai resep lezat dari pengguna lain, simpan favoritmu, dan bagikan kreasi masakanmu kepada dunia.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Fitur Utama:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Temukan ribuan resep dari berbagai kategori.'),
                      const Text('• Simpan resep favorit ke dalam koleksi pribadi.'),
                      const Text('• Bagikan resep kamu dengan komunitas HeartBite.'),
                      const Text('• Ikuti akun-akun yang menginspirasi.', style: TextStyle(height: 1.4)),
                      const SizedBox(height: 24),
                      const Text(
                        'Tentang Kami',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'HeartBite dikembangkan oleh tim kecil yang bersemangat di bidang kuliner dan teknologi. Kami percaya makanan adalah bahasa universal untuk berbagi cinta.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kelompok 23',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'HeartBite dikembangkan oleh tim kecil yang bersemangat di bidang kuliner dan teknologi. Kami percaya makanan adalah bahasa universal untuk berbagi cinta.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Versi Aplikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('HeartBite v1.0.0'),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: AuthService.isUserLoggedIn() 
                    ? () async {
                        await AuthService.signOut();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You have been signed out')),
                        );
                        Navigator.pop(context); // Close the current screen/dialog
                      }
                    : null, // Button akan disabled jika user belum login
                  style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Logout Akun'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'About',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
