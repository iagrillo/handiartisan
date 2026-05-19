import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artisan.dart';
import '../models/category.dart';
import '../utils/supabase.dart';

class ArtisanProvider extends ChangeNotifier {
  // Implements 'Near Me' filter by city/state match
  bool _nearMeEnabled = false;
  String? _nearMeCity;
  String? _nearMeState;
  void setNearMe(bool value, {double? lat, double? lng, String? city, String? state}) {
    _nearMeEnabled = value;
    if (value && city != null && state != null) {
      _nearMeCity = city;
      _nearMeState = state;
    } else {
      _nearMeCity = null;
      _nearMeState = null;
    }
    fetchArtisans();
    notifyListeners();
  }
    // For compatibility with legacy code
    void setSelectedState(String value) {
      setStateFilter(value);
    }
  List<Artisan> artisans = [];
  List<Category> categories = [];
  List<String> states = [];
  List<String> allCities = [];
  Map<String, String> _stateNameToId = {};
  List<String> get cities {
    if (state.isEmpty) return allCities;
    final stateId = _stateNameToId[state];
    if (stateId != null && _cityStateMap.containsKey(stateId)) {
      return _cityStateMap[stateId]!;
    }
    return [];
  }
  Map<String, List<String>> _cityStateMap = {};
  bool loading = false;

  String search = '';
  String category = '';
  String state = '';
  String city = '';

  ArtisanProvider() {
    fetchAll();
  }

  Future<void> fetchAll() async {
    loading = true;
    notifyListeners();

    await Future.wait([
      fetchArtisans(),
      fetchCategories(),
      fetchStates(),
      fetchCities(),
    ]);

    loading = false;
    notifyListeners();
  }

  Future<void> fetchArtisans() async {
    try {
      final client = SupabaseUtils.client;
      var query = client.from('artisans').select();

      print('[DEBUG] fetchArtisans: state="$state", city="$city", category="$category", search="$search"');

      if (_nearMeEnabled && _nearMeCity != null && _nearMeState != null) {
        query = query.eq('city', _nearMeCity!).eq('state', _nearMeState!);
      } else {
        if (search.isNotEmpty) {
          // Multi-field search: full_name, skills, category, city, state
          query = query.or(
            'full_name.ilike.%$search%,skills.ilike.%$search%,category.ilike.%$search%,city.ilike.%$search%,state.ilike.%$search%'
          );
        }
        if (category.isNotEmpty) {
          query = query.eq('category', category);
        }
        // Strict state/city filtering
        if (state.isNotEmpty) {
          query = query.eq('state', state);
        }
        if (city.isNotEmpty) {
          query = query.eq('city', city);
        }
      }

      final response = await query;
      print('[DEBUG] fetchArtisans: response count = "+${(response as List).length}"');
      artisans = (response as List)
          .map((json) => Artisan.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('[Supabase] fetchArtisans exception: $e');
      artisans = [];
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final client = SupabaseUtils.client;
      final response = await client.from('categories').select();
      if (response == null) {
        print('[Supabase] fetchCategories: Response is null');
        categories = [];
        notifyListeners();
        return;
      }
      categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('[Supabase] fetchCategories exception: $e');
      categories = [];
      notifyListeners();
    }
  }

  Future<void> fetchStates() async {
    try {
      final client = SupabaseUtils.client;
      final response = await client.from('states').select();
      if (response == null) {
        print('[Supabase] fetchStates: Response is null');
        states = [];
        _stateNameToId.clear();
        notifyListeners();
        return;
      }
      states = (response as List).map((e) => e['name'] as String).toList();
      _stateNameToId.clear();
      for (final state in response as List) {
        _stateNameToId[state['name'] as String] = state['id'].toString();
      }
      notifyListeners();
    } catch (e) {
      print('[Supabase] fetchStates exception: $e');
      states = [];
      _stateNameToId.clear();
      notifyListeners();
    }
  }

  Future<void> fetchCities() async {
    try {
      final client = SupabaseUtils.client;
      final response = await client.from('cities').select();
      if (response == null) {
        print('[Supabase] fetchCities: Response is null');
        allCities = [];
        _cityStateMap.clear();
        notifyListeners();
        return;
      }
      allCities = (response as List).map((e) => e['name'] as String).toList();
      // Build a map of state_id -> cities
      _cityStateMap.clear();
      for (final city in response as List) {
        final cityName = city['name'] as String;
        final cityStateId = city['state_id']?.toString() ?? '';
        if (!_cityStateMap.containsKey(cityStateId)) {
          _cityStateMap[cityStateId] = [];
        }
        _cityStateMap[cityStateId]!.add(cityName);
      }
      notifyListeners();
    } catch (e) {
      print('[Supabase] fetchCities exception: $e');
      allCities = [];
      _cityStateMap.clear();
      notifyListeners();
    }
  }

  List<Artisan> get featuredArtisans => artisans.where((a) => a.isFeatured == true).toList();

  void setSearch(String value) {
    search = value;
    fetchArtisans();
  }

  void setCategoryFilter(String value) {
    category = value;
    fetchArtisans();
  }

  Future<void> setStateFilter(String value) async {
    state = value;
    city = '';
    fetchArtisans();
    notifyListeners();
  }

  void setCityFilter(String value) {
    city = value;
    fetchArtisans();
  }
}