import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'welcome_pages/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bookmark/screens/bookmark_screen.dart';
import 'homepage/homepage.dart';
import 'sidebar/screens/profile_screen.dart';
import 'recipe_detail/screens/recipe_detail_screen.dart';
import 'services/auth_service.dart';

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
      ),      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreenWrapper(),
        '/home': (context) => const HomePage(),
        '/bookmark': (context) => const BookmarkScreen(),
        '/profile': (context) => const ProfileScreenWithBackend(),
      },
      // Handle dynamic routes that need parameters
      onGenerateRoute: (settings) {
        if (settings.name == '/recipe-detail') {
          // Extract recipe ID from arguments
          final args = settings.arguments as Map<String, dynamic>;
          final recipeId = args['recipeId'];
          return MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipeId),
          );
        }
        return null;
      },
    );
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Check login status after widget is built with slight delay
    // to avoid flash of welcome screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }
  Future<void> _checkLoginStatus() async {
    // Short delay to allow smooth transitions
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted && AuthService.isUserLoggedIn()) {
      // If user is already logged in, redirect to homepage
      Navigator.of(context).pushReplacementNamed('/home');
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8E1616),
              ),
            )
          : const WelcomeScreen(),
    );
  }
}
