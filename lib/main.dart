import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_pages/welcome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try { 
    await dotenv.load(fileName: ".env");
    print("SUCCESS: .env file loaded.");
  } catch (e) {
    print("ERROR loading .env file: $e");
  }

  // Add this check after loading the .env file
  if (dotenv.env['SUPABASE_URL'] == null || 
      dotenv.env['SUPABASE_URL']!.isEmpty ||
      dotenv.env['SUPABASE_ANON_KEY'] == null || 
      dotenv.env['SUPABASE_ANON_KEY']!.isEmpty) {
    throw Exception('Missing Supabase credentials in .env file');
  }

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    print("SUCCESS: Supabase initialized.");
  } catch (e) {
    print("ERROR initializing Supabase: $e");
  }
  
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
      home: const WelcomeScreen(),
    );
  }
}
