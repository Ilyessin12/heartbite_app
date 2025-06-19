// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; // Add this import for File class

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // User methods
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  // Database operations
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _client.from('users').select();
    return response as List<Map<String, dynamic>>;
  }
  
  // Example: Save user profile
  Future<void> saveUserProfile({
    required String userId,
    required String displayName,
    required String username,
    String? coverImageUrl,
    String? profileImageUrl,
  }) async {
    await _client.from('user_profiles').upsert({
      'user_id': userId,
      'display_name': displayName,
      'username': username,
      'cover_image_url': coverImageUrl,
      'profile_image_url': profileImageUrl,
    });
  }
  
  // Image upload example
  Future<String> uploadImage(String filePath, String folder) async {
    final fileName = filePath.split('/').last;
    final file = File(filePath);
    
    await _client.storage
        .from('profile_images')
        .upload('$folder/$fileName', file);
    
    // Get public URL
    final url = _client.storage
        .from('profile_images')
        .getPublicUrl('$folder/$fileName');
        
    return url;
  }
}