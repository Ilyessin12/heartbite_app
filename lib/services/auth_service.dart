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
  
  // Fungsi untuk mendapatkan URL foto profil dari tabel users
  static Future<String?> getUserProfilePicture() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;
      
      final response = await Supabase.instance.client
          .from('users')
          .select('profile_picture')
          .eq('id', userId)
          .single();
      
      return response['profile_picture'] as String?;
    } catch (e) {
      print('Error saat mengambil foto profil: $e');
      return null;
    }
  }
}