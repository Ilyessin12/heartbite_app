import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';


class AuthService {
  static bool isUserLoggedIn() {
    return Supabase.instance.client.auth.currentUser != null;
  }
  
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
  
  static Map<String, dynamic>? getCurrentUserData() {
    return Supabase.instance.client.auth.currentUser?.userMetadata;
  }
  
  // Alternatif menggunakan wrapper
  static bool isUserLoggedInAlt() {
    return SupabaseClientWrapper().auth.currentUser != null;
  }
  
  // Fungsi untuk sign out (logout)
  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}