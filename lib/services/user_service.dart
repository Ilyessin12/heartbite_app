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
    required String? phone,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'full_name': fullName},
    );

    // Jika signup berhasil, buat entry baru di tabel users
    if (res.user != null) {
      await _supabase.from('users').insert({
        'id': res.user!.id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'phone': phone,
        'password_hash': null, // Password sudah dihandle oleh Supabase Auth
      });
    }

    return res;
  }

  /// Login user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
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

  /// Request password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo:
          'com.example.heartbite_tubesprovis://auth/reset', // sesuaikan dengan deep link
    );
  }

  /// Update password (setelah user klik link di email)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _supabase.from('users').select().eq('id', userId).single();

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

    await _supabase.from('users').update(updates).eq('id', userId);
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return false;

    // Hapus karakter @ jika ada di awal username
    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    final result = await _supabase
        .from('users')
        .select('username')
        .eq('username', username)
        .limit(1);

    // Jika result kosong, username tersedia
    return result.isEmpty;
  }

  /// Check if email exists in the database
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .limit(1);
      
      return response.length > 0;
    } catch (e) {
      print('Error checking email: $e');
      // Jika error, anggap email tidak ada untuk aman
      return false;
    }
  }
}
