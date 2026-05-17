import 'package:flutter/foundation.dart' hide Category;
import 'package:postgrest/postgrest.dart';

import '../features/models/artisan.dart';
import '../features/models/category.dart';
import '../features/utils/supabase.dart';

class ArtisanService {
  final String _table = 'artisans';

  /*
  ─────────────────────────────────────────────
  FETCH CATEGORIES
  ─────────────────────────────────────────────
  */
  Future<List<Category>> fetchCategories() async {
    final response = await SupabaseUtils.client.from('categories').select();

    return (response as List).map((json) => Category.fromJson(json)).toList();
  }

  /*
  ─────────────────────────────────────────────
  FETCH STATES
  ─────────────────────────────────────────────
  */
  Future<List<String>> fetchStates() async {
    final response =
        await SupabaseUtils.client.from('states').select('name').order('name');

    return (response as List).map((e) => e['name'] as String).toList();
  }

  /*
  ─────────────────────────────────────────────
  FETCH CITIES
  ─────────────────────────────────────────────
  */
  Future<List<String>> fetchCities(String state) async {
    final stateData = await SupabaseUtils.client
        .from('states')
        .select('id')
        .eq('name', state)
        .single();

    final stateId = stateData['id'];

    final response = await SupabaseUtils.client
        .from('cities')
        .select('name')
        .eq('state_id', stateId)
        .order('name');

    return (response as List).map((e) => e['name'] as String).toList();
  }

  /*
  ─────────────────────────────────────────────
  FETCH ARTISANS (WITH FILTERS)
  ─────────────────────────────────────────────
  */
  Future<List<Artisan>> fetchArtisans({
    String? search,
    String? category,
    String? state,
    String? city,
  }) async {
    var query =
        SupabaseUtils.client.from(_table).select().eq('status', 'active');

    if (search != null && search.isNotEmpty) {
      query = query.ilike('full_name', '%$search%');
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (state != null && state.isNotEmpty) {
      query = query.eq('state', state);
    }

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }

    try {
      final response = await query;
      print('[Supabase] fetchArtisans response: ${response.length} rows');
      if (response.isNotEmpty) {
        print(
            '[Supabase] First artisan profileImageUrl: ${response.first['profile_image_url']}');
      }
      return (response as List).map((json) => Artisan.fromJson(json)).toList();
    } catch (e) {
      print('[Supabase] fetchArtisans error: $e');
      return [];
    }
  }

  /*
  ─────────────────────────────────────────────
  FETCH ARTISAN BY ID
  ─────────────────────────────────────────────
  */
  Future<Artisan?> fetchArtisanById(String id) async {
    final response =
        await SupabaseUtils.client.from(_table).select().eq('id', id).single();

    return Artisan.fromJson(response);
  }

  /*
  ─────────────────────────────────────────────
  ADD ARTISAN
  ─────────────────────────────────────────────
  */
  Future<bool> addArtisan(Artisan artisan) async {
    await SupabaseUtils.client.from(_table).insert(artisan.toJson());

    return true;
  }

  /*
  ─────────────────────────────────────────────
  UPDATE ARTISAN
  ─────────────────────────────────────────────
  */
  Future<bool> updateArtisan(String id, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data)..remove('id');
      final currentUserEmail =
          SupabaseUtils.client.auth.currentUser?.email?.trim().toLowerCase();
      final phone = payload['phone']?.toString().trim();
      final candidateIds = <String>{id};

      if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
        final emailRows = await SupabaseUtils.client
            .from(_table)
            .select('id')
            .eq('email', currentUserEmail);

        for (final row in emailRows) {
          final candidateId = row['id']?.toString();
          if (candidateId != null && candidateId.isNotEmpty) {
            candidateIds.add(candidateId);
          }
        }
      }

      if (phone != null && phone.isNotEmpty) {
        final phoneRows = await SupabaseUtils.client
            .from(_table)
            .select('id')
            .eq('phone', phone);

        for (final row in phoneRows) {
          final candidateId = row['id']?.toString();
          if (candidateId != null && candidateId.isNotEmpty) {
            candidateIds.add(candidateId);
          }
        }
      }

      for (final candidateId in candidateIds) {
        final updatedRow = await SupabaseUtils.client
            .from(_table)
            .update(payload)
            .eq('id', candidateId)
            .select('id, email')
            .maybeSingle();

        if (updatedRow != null) {
          debugPrint(
            'updateArtisan: updated artisan ${updatedRow['id']} using candidate id $candidateId',
          );
          return true;
        }
      }

      if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
        final updatedByEmail = await SupabaseUtils.client
            .from(_table)
            .update(payload)
            .eq('email', currentUserEmail)
            .select('id, email');

        if (updatedByEmail.isNotEmpty) {
          debugPrint(
            'updateArtisan: updated ${updatedByEmail.length} artisan row(s) using email fallback',
          );
          return true;
        }
      }

      if (phone != null && phone.isNotEmpty) {
        final updatedByPhone = await SupabaseUtils.client
            .from(_table)
            .update(payload)
            .eq('phone', phone)
            .select('id, email');

        if (updatedByPhone.isNotEmpty) {
          debugPrint(
            'updateArtisan: updated ${updatedByPhone.length} artisan row(s) using phone fallback',
          );
          return true;
        }
      }

      debugPrint(
        'updateArtisan: no row updated for id=$id. This is usually caused by RLS blocking the update or the signed-in user not matching the artisan record.',
      );
      return false;
    } on PostgrestException catch (e) {
      debugPrint('updateArtisan PostgrestException: ${e.message}');
      debugPrint('details: ${e.details}, hint: ${e.hint}, code: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Update artisan error: $e');
      return false;
    }
  }

  /*
  ─────────────────────────────────────────────
  DELETE ARTISAN
  ─────────────────────────────────────────────
  */
  Future<bool> deleteArtisan(String id) async {
    await SupabaseUtils.client.from(_table).delete().eq('id', id);

    return true;
  }
}
