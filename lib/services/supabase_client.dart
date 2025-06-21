import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton class untuk mengakses Supabase client secara global
class SupabaseClientWrapper {
  static final SupabaseClientWrapper _instance = SupabaseClientWrapper._internal();
  
  factory SupabaseClientWrapper() {
    return _instance;
  }
  
  SupabaseClientWrapper._internal();
  
  /// Mengakses supabase client
  SupabaseClient get client => Supabase.instance.client;
  
  /// Mengakses auth client
  GoTrueClient get auth => client.auth;
}