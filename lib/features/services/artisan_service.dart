import 'package:flutter/foundation.dart' hide Category;
import 'package:handihub_artisan_app/features/models/artisan.dart';
import 'package:handihub_artisan_app/features/models/category.dart';
import 'package:handihub_artisan_app/features/utils/supabase.dart';
import 'package:postgrest/postgrest.dart';

class ArtisanService {
  final String _table = 'artisans';

  /*
  ─────────────────────────────────────────────
  FETCH ARTISANS (WITH FILTERS)
  ─────────────────────────────────────────────
  */
  Future<List<Artisan>> fetchArtisans({
    String? status,
    String? state,
    String? city,
    String? category,
    String? search,
  }) async {
    var query = SupabaseUtils.client.from(_table).select();

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    if (state != null && state.isNotEmpty) {
      query = query.eq('state', state);
    }

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('full_name', '%$search%');
    }

    final response = await query;

    return (response as List).map((e) => Artisan.fromJson(e)).toList();
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
    final stateRow = await SupabaseUtils.client
        .from('states')
        .select('id')
        .eq('name', state)
        .single();

    final stateId = stateRow['id'];

    final response = await SupabaseUtils.client
        .from('cities')
        .select('name')
        .eq('state_id', stateId)
        .order('name');

    return (response as List).map((e) => e['name'] as String).toList();
  }

  /*
  ─────────────────────────────────────────────
  FETCH CATEGORIES
  ─────────────────────────────────────────────
  */
  Future<List<Category>> fetchCategories() async {
    final response =
        await SupabaseUtils.client.from('categories').select().order('name');

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  /*
  ─────────────────────────────────────────────
  FETCH BY ID
  ─────────────────────────────────────────────
  */
  Future<Artisan?> fetchArtisanById(String id) async {
    final response =
        await SupabaseUtils.client.from(_table).select().eq('id', id).single();

    return Artisan.fromJson(response);
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
  ADD ARTISAN
  ─────────────────────────────────────────────
  */
  Future<bool> addArtisan(Artisan artisan) async {
    await SupabaseUtils.client.from(_table).insert(artisan.toJson());

    return true;
  }

  /*
  ─────────────────────────────────────────────
  DELETE ARTISAN
  ─────────────────────────────────────────────
  */
  Future<bool> deleteArtisan(String id) async {
    try {
      final response = await SupabaseUtils.client
          .from(_table)
          .delete()
          .eq('id', id)
          .select();

      // Check if any rows were actually deleted
      if (response.isEmpty) {
        debugPrint('deleteArtisan: no row found with id=$id');
        return false;
      }
      return true;
    } on PostgrestException catch (e) {
      debugPrint('deleteArtisan PostgrestException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('deleteArtisan error: $e');
      return false;
    }
  }
}
