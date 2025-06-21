import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_client.dart';

class UserService {
  final _supabase = SupabaseClientWrapper().client;
  
  /// Signup new user
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    required String username,
    required String fullName,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email, 
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      }
    );
    
    // Jika signup berhasil, buat entry baru di tabel users
    if (res.user != null) {
      await _supabase.from('users').insert({
        'id': res.user!.id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'password_hash': null, // Password sudah dihandle oleh Supabase Auth
      });
    }
    
    return res;
  }
  
  /// Login user
  Future<AuthResponse> signIn({
    required String email, 
    required String password
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Logout user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    final response = await _supabase
      .from('users')
      .select()
      .eq('id', userId)
      .single();
      
    return response;
  }
  
  /// Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? profilePicture,
    String? coverPicture,
    String? phone,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final Map<String, dynamic> updates = {};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (profilePicture != null) updates['profile_picture'] = profilePicture;
    if (coverPicture != null) updates['cover_picture'] = coverPicture;
    if (phone != null) updates['phone'] = phone;
    
    await _supabase
      .from('users')
      .update(updates)
      .eq('id', userId);
  }
}