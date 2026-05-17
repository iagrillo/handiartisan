import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility for initializing and accessing Supabase client.
///
/// Usage: Call [SupabaseUtils.init] at app startup, passing the URL and anon key.
/// Recommended: Use flutter_dotenv to load these from a .env file.
class SupabaseUtils {
  static SupabaseClient? _client;

  /// Initialize Supabase (call this at app startup)
  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseUtils.init first.');
    }
    return _client!;
  }
}