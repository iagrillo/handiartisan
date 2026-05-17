import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/utils/supabase.dart';

class UserProfileService {
  static SupabaseClient get _client => SupabaseUtils.client;

  static Future<void> ensureProfileForUser(User user) async {
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (_) {
      // Ignore here so auth state still works even before the SQL migration is applied.
    }
  }

  static Future<bool> isWalletPinSet(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('wallet_pin_set')
          .eq('id', userId)
          .maybeSingle();

      return row?['wallet_pin_set'] == true;
    } catch (_) {
      return false;
    }
  }

  static String hashWalletPin({required String userId, required String pin}) {
    final salted = 'handihub_wallet_pin::$userId::$pin';
    return sha256.convert(utf8.encode(salted)).toString();
  }

  static Future<void> setWalletPin({
    required String userId,
    required String pinHash,
    String? email,
  }) async {
    try {
      await _client.rpc('set_wallet_pin', params: {'pin_hash': pinHash});
      return;
    } catch (_) {
      await _client.from('profiles').upsert({
        'id': userId,
        'email': email,
        'wallet_pin_hash': pinHash,
        'wallet_pin_set': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    }
  }

  static Future<bool> verifyWalletPin({
    required String userId,
    required String pin,
  }) async {
    final pinHash = hashWalletPin(userId: userId, pin: pin);

    try {
      final result =
          await _client.rpc('verify_wallet_pin', params: {'pin_hash': pinHash});
      return result == true;
    } catch (_) {
      final row = await _client
          .from('profiles')
          .select('wallet_pin_hash, wallet_pin_set')
          .eq('id', userId)
          .maybeSingle();

      return row != null &&
          row['wallet_pin_set'] == true &&
          row['wallet_pin_hash'] == pinHash;
    }
  }
}
