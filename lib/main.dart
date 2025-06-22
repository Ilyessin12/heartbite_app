import 'dart:async'; // Import untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago; // Import untuk timeago
import 'welcome_pages/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/test_supabase.dart';
import 'bookmark/screens/bookmark_screen.dart';
import 'test/test_login.dart';
import 'services/auth_service.dart'; // Import untuk sign out
import 'services/supabase_client.dart'; // Import untuk akses database
import 'homepage/homepage.dart';
import 'sidebar/screens/profile_screen.dart';

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

  timeago.setLocaleMessages('id', timeago.IdMessages());

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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreenWrapper(),
        '/home': (context) => const HomePage(),
        '/bookmark': (context) => const BookmarkScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// Tambahkan class baru ini
class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  String? _userEmail;
  String? _userFullName;
  String? _username;
  bool _isLoading = false;
  // Subscription untuk perubahan status autentikasi
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();

    // Dengarkan perubahan status autentikasi
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      // Perbarui UI saat status autentikasi berubah
      if (data.event == AuthChangeEvent.signedIn) {
        print('User signed in');
        _fetchUserInfo();
      } else if (data.event == AuthChangeEvent.signedOut) {
        print('User signed out');
        if (mounted) {
          setState(() {
            _userEmail = null;
            _userFullName = null;
            _username = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    if (!AuthService.isUserLoggedIn()) {
      if (mounted) {
        // Add this check
        setState(() {
          _userEmail = null;
          _userFullName = null;
          _username = null;
        });
      }
      return;
    }

    if (mounted) {
      // Add this check
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {
        // Ambil data user dari Supabase
        final userData =
            await SupabaseClientWrapper().client
                .from('users')
                .select()
                .eq('id', userId)
                .single();

        if (mounted) {
          // Add this check
          setState(() {
            _userEmail = Supabase.instance.client.auth.currentUser?.email;
            _userFullName = userData['full_name'];
            _username = userData['username'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error saat fetch user info: $e');
      if (mounted) {
        // Add this check
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk sign out
  void _signOut(BuildContext context) async {
    // Konfirmasi logout
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Keluar'),
              ),
            ],
          ),
    );

    // Jika user konfirmasi logout
    if (shouldLogout == true) {
      try {
        await AuthService.signOut();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));
        _fetchUserInfo(); // Refresh UI
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Hapus AppBar
      body: Stack(
        children: [
          // Main content
          const WelcomeScreen(),

          // User info panel
          if (AuthService.isUserLoggedIn())
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akun yang login:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8E1616),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Email',
                              _userEmail ?? 'Tidak tersedia',
                            ),
                            _buildInfoRow(
                              'Nama',
                              _userFullName ?? 'Tidak tersedia',
                            ),
                            _buildInfoRow(
                              'Username',
                              _username ?? 'Tidak tersedia',
                            ),
                          ],
                        ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Sign Out - hanya muncul saat user login
          if (AuthService.isUserLoggedIn()) ...[
            FloatingActionButton(
              onPressed: () => _signOut(context),
              backgroundColor: const Color(0xFFFF5252),
              child: const Icon(Icons.logout, color: Colors.white),
              heroTag: "logout",
              tooltip: 'Sign Out',
            ),
            const SizedBox(height: 10),
          ],

          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestLoginScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.login, color: Colors.white),
            heroTag: "login",
            tooltip: 'Test Login',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/bookmark');
            },
            backgroundColor: const Color(0xFF8E1616),
            child: const Icon(Icons.bookmark, color: Colors.white),
            heroTag: "bookmark",
            tooltip: 'Bookmarks',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
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
          const SizedBox(height: 10),
          // ✅ Floating Action Button untuk ProfileScreen
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.person, color: Colors.white),
            heroTag: "profile",
            tooltip: 'Profile Page',
          ),
          const SizedBox(height: 10),
          // ✅ Floating Action Button untuk HomePage
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            backgroundColor: const Color.fromARGB(255, 200, 128, 13),
            child: const Icon(Icons.home, color: Colors.white),
            heroTag: "homepage",
            tooltip: 'Home Page',
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat baris informasi
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
