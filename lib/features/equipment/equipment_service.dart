import 'package:supabase_flutter/supabase_flutter.dart';

class EquipmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchEquipment({
    String? tab,
    String? search,
    String? location,
    String? state,
    String? city,
    String? category,
  }) async {
    try {
      List<Map<String, dynamic>> filtered = [];
      
      // If Services tab, fetch from services table
      if (tab != null && tab.toLowerCase() == 'services') {
        final servicesResponse = await _client.from('services').select();
        print('[Supabase] fetchEquipment (Services): Got ${servicesResponse.length} records');
        
        // Filter for approved status
        filtered = servicesResponse.where((e) => e['status'] == 'approved').toList();
        
        // Convert services to equipment format for display
        filtered = filtered.map((s) => {
          'id': s['id'],
          'name': s['name'],
          'category': 'Services',
          'type': 'Services',
          'state': s['state'],
          'city': s['city'],
          'contact_phone': s['contact_number'],
          'description': s['experience_summary'],
          'specs': s['certifications'],
          'mobility': s['mobility'],
          'service_maintenance': s['service_maintenance'],
          'service_repair': s['service_repair'],
          'service_installation': s['service_installation'],
          'service_diagnostics': s['service_diagnostics'],
          'created_at': s['created_at'],
        }).toList();
        
        // Filter by search
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          filtered = filtered.where((e) => 
            ((e['name'] ?? '').toString().toLowerCase().contains(searchLower)) ||
            ((e['description'] ?? '').toString().toLowerCase().contains(searchLower))
          ).toList();
        }
        
        // Filter by location
        if (location != null && location.isNotEmpty && location != 'All Locations') {
          filtered = filtered.where((e) => (e['city'] ?? '') == location).toList();
        }
        
        print('[Supabase] fetchEquipment (Services): Returning ${filtered.length} records');
        return filtered;
      }
      
      // If Parts tab, fetch from parts table
      if (tab != null && tab.toLowerCase() == 'parts') {
        final partsResponse = await _client.from('parts').select();
        print('[Supabase] fetchEquipment (Parts): Got ${partsResponse.length} records');
        
        // Filter for approved status
        filtered = partsResponse.where((e) => e['status'] == 'approved').toList();
        
        // Convert parts to equipment format for display
        filtered = filtered.map((p) => {
          'id': p['id'],
          'name': p['name'],
          'category': p['category'] ?? 'Parts',
          'type': 'Parts',
          'sub_category': p['sub_category'],
          'brand': p['brand'],
          'model': p['model'],
          'part_number': p['part_number'],
          'compatible_with': p['compatible_with'],
          'price': p['price'],
          'price_type': p['price_type'],
          'state': p['state'],
          'city': p['city'],
          'contact_name': p['contact_name'],
          'contact_phone': p['contact_phone'],
          'description': p['description'],
          'in_stock': p['in_stock'],
          'quantity': p['quantity'],
          'created_at': p['created_at'],
        }).toList();
        
        // Filter by search
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          filtered = filtered.where((e) => 
            ((e['name'] ?? '').toString().toLowerCase().contains(searchLower)) ||
            ((e['description'] ?? '').toString().toLowerCase().contains(searchLower)) ||
            ((e['part_number'] ?? '').toString().toLowerCase().contains(searchLower)) ||
            ((e['brand'] ?? '').toString().toLowerCase().contains(searchLower))
          ).toList();
        }
        
        // Filter by location
        if (location != null && location.isNotEmpty && location != 'All Locations') {
          filtered = filtered.where((e) => (e['city'] ?? '') == location).toList();
        }
        
        print('[Supabase] fetchEquipment (Parts): Returning ${filtered.length} records');
        return filtered;
      }
      
      // For other tabs, fetch from equipment table
      final response = await _client.from('equipment').select();
      
      print('[Supabase] fetchEquipment: Got ${response.length} records');
      
      // Filter for approved status in code
      filtered = response.where((e) => e['status'] == 'approved').toList();
      
      // Filter by tab/type
      if (tab != null && tab.isNotEmpty && tab != 'All') {
        String mappedType = tab.toLowerCase();
        if (mappedType == 'sales') mappedType = 'sale';
        if (mappedType == 'parts') mappedType = 'parts';
        filtered = filtered.where((e) => (e['type'] ?? '').toString().toLowerCase() == mappedType).toList();
      }

      // Filter by category
      if (category != null && category.isNotEmpty && category != 'All Categories') {
        filtered = filtered.where((e) => (e['category'] ?? '') == category).toList();
      }

      // Filter by search
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        filtered = filtered.where((e) => 
          ((e['name'] ?? '').toString().toLowerCase().contains(searchLower)) ||
          ((e['description'] ?? '').toString().toLowerCase().contains(searchLower))
        ).toList();
      }

      // Filter by location
      if (location != null && location.isNotEmpty && location != 'All Locations') {
        filtered = filtered.where((e) => (e['city'] ?? '') == location).toList();
      }

      // Filter by state
      if (state != null && state.isNotEmpty) {
        filtered = filtered.where((e) => (e['state'] ?? '') == state).toList();
      }

      // Filter by city
      if (city != null && city.isNotEmpty) {
        filtered = filtered.where((e) => (e['city'] ?? '') == city).toList();
      }

      // Sort by created_at descending
      filtered.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      print('[Supabase] fetchEquipment: Returning ${filtered.length} records after filtering');
      return filtered;
    } catch (e) {
      print('[Supabase] fetchEquipment exception: $e');
      return [];
    }
  }

  Future<void> insertTestWalletData() async {
    final client = Supabase.instance.client;
    try {
      final response = await client.from('wallet').insert({
        'phone': '08063923790',
        'email': 'israel.grillo@gmail.com',
        'city': 'ibadan',
        'balance': 1000,
        'created_at': DateTime.now().toIso8601String(),
      }).select();
      print('Test wallet data inserted successfully: $response');
    } catch (e) {
      print('Error inserting test wallet: $e');
    }
  }
}