import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'welcome_pages/welcome.dart'; // No longer the primary entry point
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'screens/test_supabase.dart'; // No longer needed here
import 'myMain.dart'; // Import myMain.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try { 
    await dotenv.load(fileName: ".env");
    print("SUCCESS: .env file loaded.");
  } catch (e) {
    print("ERROR loading .env file: $e");
    // It's critical that .env loads for Supabase keys. Consider how to handle this error.
    // For now, it will proceed, but Supabase init will likely fail if keys are missing.
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print("ERROR: SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file.");
    // Optionally, stop the app or show an error UI.
    // For now, execution continues, Supabase.initialize will likely throw an error.
  }

  await Supabase.initialize(
    url: supabaseUrl ?? '', // Pass empty string if null, Supabase client will handle error.
    anonKey: supabaseAnonKey ?? '', // Pass empty string if null.
  );

  // runApp(const MyApp()); // MyApp from myMain.dart will be used if main() in myMain.dart is the entry
  // If lib/main.dart is the true entry point, then we use the MyApp class defined here.
  // The request was to connect main.dart to myMain.dart.
  // myMain.dart also has a main() and MyApp. This can be confusing.
  // Assuming lib/main.dart's main() is the actual entry point for the app.
  runApp(const MainApp()); // Renamed to avoid conflict if myMain.dart's MyApp is different
}

// Renamed this class to MainApp to avoid conflicts if myMain.dart also defines a MyApp.
// This MainApp will now use NavigationPage from myMain.dart as its home.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E1616),
          primary: const Color(0xFF8E1616).withOpacity(0.2), // Adjusted opacity for primary
          onPrimary: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E1616).withOpacity(0.3), // Adjusted opacity for buttons
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
      // Use NavigationPage from myMain.dart as the home screen.
      // This assumes NavigationPage is the intended main navigator.
      home: const NavigationPage(),
    );
  }
}

// HomeScreenWrapper is no longer needed as NavigationPage will be the home.
// class HomeScreenWrapper extends StatelessWidget {
//   const HomeScreenWrapper({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: const WelcomeScreen(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const TestSupabaseScreen()),
//           );
//         },
//         backgroundColor: const Color(0xFF1E90FF),
//         child: const Icon(Icons.science, color: Colors.white),
//         tooltip: 'Test Supabase',
//       ),
//     );
//   }
// }
