import 'package:supabase_flutter/supabase_flutter.dart';

class _InMemoryLocalStorage implements LocalStorage {
  String? _persistSession;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _persistSession != null;

  @override
  Future<String?> accessToken() async => _persistSession;

  @override
  Future<void> removePersistedSession() async {
    _persistSession = null;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _persistSession = persistSessionString;
  }
}

class SupabaseUtils {
  static SupabaseClient? _client;

  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _InMemoryLocalStorage(),
      ),
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseUtils.init first.');
    }
    return _client!;
  }
}