import 'package:flutter/material.dart';import 'package:supabase_flutter/supabase_flutter.dart';import '../features/models/artisan.dart';import '../features/models/category.dart';import '../features/utils/supabase.dart';class ArtisanProvider extends ChangeNotifier {  List<Artisan> artisans = [];  List<Category> categories = [];  List<String> states = [];  List<String> cities = [];  bool loading = false;  String search = '';  String category = '';  String state = '';  String city = '';  ArtisanProvider() {    fetchAll();  }  Future<void> fetchAll() async {    loading = true;    notifyListeners();    await Future.wait([      fetchArtisans(),      fetchCategories(),      fetchStates(),      fetchCities(),    ]);    loading = false;    notifyListeners();  }  Future<void> fetchArtisans() async {    final client = SupabaseUtils.client;    var query = client.from('artisans').select().eq('status', 'active');

    final s = search.trim();
    final c = category.trim();
    final st = state.trim();
    final ci = city.trim();

    if (s.isNotEmpty) {
      query = query.or(
        'full_name.ilike.%$s%,category.ilike.%$s%,city.ilike.%$s%,state.ilike.%$s%',
      );
    }
    if (c.isNotEmpty) {
      query = query.eq('category', c);
    }
    if (st.isNotEmpty) {
      query = query.eq('state', st);
    }
    if (ci.isNotEmpty) {
      query = query.eq('city', ci);
    }

    final response = await query;
    artisans = (response as List)
        .map((json) => Artisan.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }  Future<void> fetchCategories() async {    final client = SupabaseUtils.client;    final response = await client.from('categories').select();    categories = (response as List)        .map((json) => Category.fromJson(json as Map<String, dynamic>))        .toList();    notifyListeners();  }  Future<void> fetchStates() async {    final client = SupabaseUtils.client;    final response = await client.from('states').select();    states = (response as List).map((e) => e['name'] as String).toList();    notifyListeners();  }  Future<void> fetchCities() async {    final client = SupabaseUtils.client;    final response = await client.from('cities').select();    cities = (response as List).map((e) => e['name'] as String).toList();    notifyListeners();  }  void setSearch(String value) {    search = value;    fetchArtisans();  }  void setCategoryFilter(String value) {    category = value;    fetchArtisans();  }  Future<void> setStateFilter(String value) async {    state = value;    await fetchCities();    fetchArtisans();  }  void setCityFilter(String value) {    city = value;    fetchArtisans();  }}