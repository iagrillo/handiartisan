import 'package:flutter/foundation.dart';
import 'package:postgrest/postgrest.dart';

import '../features/models/artisan.dart';
import '../features/utils/supabase.dart';

class ArtisanService {
  static const String _table = 'artisans';

  Future<Artisan?> fetchArtisanById(String id) async {
    try {
      final row = await SupabaseUtils.client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return Artisan.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      debugPrint('fetchArtisanById PostgrestException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('fetchArtisanById error: $e');
      return null;
    }
  }

  Future<bool> updateArtisan(String id, Map<String, dynamic> data) async {
    try {
      // Keep payload clean
      final payload = Map<String, dynamic>.from(data);

      final updatedRow = await SupabaseUtils.client
          .from(_table)
          .update(payload)
          .eq('id', id)
          .select('id')
          .maybeSingle();

      final ok = updatedRow != null;
      if (!ok) {
        debugPrint('updateArtisan: no row updated for id=$id');
      }
      return ok;
    } on PostgrestException catch (e) {
      debugPrint('updateArtisan PostgrestException: ${e.message}');
      debugPrint('details: ${e.details}, hint: ${e.hint}, code: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('updateArtisan error: $e');
      return false;
    }
  }

  Future<bool> updateProfileImage({
    required String artisanId,
    required String imageUrl,
  }) async {
    return updateArtisan(artisanId, {'profile_image_url': imageUrl});
  }
}