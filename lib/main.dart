import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'welcome_pages/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/test_supabase.dart'; // Tambahkan import ini
import 'bookmark/screens/bookmark_screen.dart'; // Import bookmark screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("SUCCESS: .env file loaded.");
  } catch (e) {
    print("ERROR loading .env file: $e");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E1616),
          primary: const Color(0xFF8E1616).withOpacity(0.2),
          onPrimary: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E1616).withOpacity(0.3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
      ),
      home: const HomeScreenWrapper(),
    );
  }
}

// Tambahkan class baru ini
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          const WelcomeScreen(), // Tetap menggunakan WelcomeScreen sebagai konten utama
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookmarkScreen()),
              );
            },
            backgroundColor: const Color(0xFF8E1616),
            child: const Icon(Icons.bookmark, color: Colors.white),
            heroTag: "bookmark",
            tooltip: 'Bookmarks',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              // Navigasi ke test_supabase.dart saat tombol ditekan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestSupabaseScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF1E90FF),
            child: const Icon(Icons.science, color: Colors.white),
            heroTag: "test",
            tooltip: 'Test Supabase',
          ),
        ],
      ),
    );
  }
}
