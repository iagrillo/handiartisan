import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreProvider extends ChangeNotifier {
  List<Map<String, dynamic>> stores = [];
  List<Map<String, dynamic>> featuredStores = [];
  bool loading = false;

  String search = '';
  String category = '';
  String state = '';
  String city = '';

  List<String> allStates = [];
  List<String> allCities = [];
  Map<String, List<String>> stateCityMap = {};

  StoreProvider() {
    fetchStores();
    fetchStatesAndCities();
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> fetchStores() async {
    loading = true;
    notifyListeners();
    try {
      var query = _client.from('stores').select().eq('status', 'approved');
      final s = search.trim();
      final c = category.trim();
      final st = state.trim();
      final ci = city.trim();
      print('[DEBUG] fetchStores: location_state="$st", location_city="$ci", category="$c", search="$s"');
      // Multi-field search
      if (s.isNotEmpty) {
        query = query.or('name.ilike.%$s%,category.ilike.%$s%,location_city.ilike.%$s%,location_state.ilike.%$s%');
      }
      if (c.isNotEmpty) {
        query = query.eq('category', c);
      }
      if (st.isNotEmpty) {
        query = query.eq('location_state', st);
      }
      if (ci.isNotEmpty) {
        query = query.eq('location_city', ci);
      }
      final response = await query.order('created_at', ascending: false);
      print('[DEBUG] fetchStores: response count = "+${(response as List).length}"');
      stores = List<Map<String, dynamic>>.from(response as List);
      featuredStores = stores.where((row) {
        final isFeatured = row['is_featured'] == true;
        final rating = (row['rating'] is num) ? (row['rating'] as num).toDouble() : 0.0;
        return isFeatured || rating >= 4.5;
      }).toList();
    } catch (e) {
      print('[Supabase] fetchStores exception: $e');
      stores = [];
      featuredStores = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    search = value;
    fetchStores();
  }

  void setCategory(String value) {
    category = value;
    fetchStores();
  }

  void setState(String value) {
    state = value;
    city = '';
    fetchStores();
    notifyListeners();
  }

  void setCity(String value) {
    city = value;
    fetchStores();
  }

  Future<void> fetchStatesAndCities() async {
    try {
      final rows = await _client.from('stores').select('location_state, location_city').eq('status', 'approved').limit(5000);
      final data = List<Map<String, dynamic>>.from(rows as List);

      final states = <String>{};
      final cities = <String>{};
      final map = <String, Set<String>>{};

      for (final row in data) {
        final st = (row['location_state'] ?? '').toString().trim();
        final ct = (row['location_city'] ?? '').toString().trim();

        if (st.isNotEmpty) {
          states.add(st);
          map.putIfAbsent(st, () => <String>{});
        }
        if (ct.isNotEmpty) {
          cities.add(ct);
          if (st.isNotEmpty) map[st]!.add(ct);
        }
      }

      allStates = states.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      allCities = cities.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      stateCityMap = {
        for (final e in map.entries)
          e.key: (e.value.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))),
      };

      notifyListeners();
    } catch (_) {
      allStates = [];
      allCities = [];
      stateCityMap = {};
      notifyListeners();
    }
  }

  List<String> getCitiesForState(String selectedState) {
    if (selectedState.trim().isEmpty) return allCities;
    return stateCityMap[selectedState] ?? [];
  }

  Future<bool> updateStore(String id, Map<String, dynamic> data) async {
    try {
      debugPrint('Updating store $id with data: $data');
      await _client.from('stores').update(data).eq('id', id);
      debugPrint('Store update successful, fetching stores...');
      await fetchStores();
      debugPrint('Stores fetched after update');
      return true;
    } catch (e) {
      debugPrint('updateStore error: $e');
      return false;
    }
  }
}