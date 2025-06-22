import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;
  
  // Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;
}
