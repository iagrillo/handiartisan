import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  runApp(const TestJobApp());
}

class TestJobApp extends StatelessWidget {
  const TestJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Create Test Job')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: createTestJob,
                child: const Text('Create Test Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> createTestJob() async {
  final client = Supabase.instance.client;
  
  try {
    // First get an artisan ID
    final artisans = await client.from('artisans').select('id').limit(1);
    if (artisans.isEmpty) {
      print('No artisans found');
      return;
    }
    
    final artisanId = artisans.first['id'];
    
    // Create a test job
    final job = await client.from('jobs').insert({
      'job_reference': 'TEST_JOB_${DateTime.now().millisecondsSinceEpoch}',
      'artisan_id': artisanId,
      'customer_email': 'test@example.com',
      'customer_phone': '08021234567',
      'customer_name': 'Test Customer',
      'service_type': 'outcall',
      'description': 'Test outcall job',
      'address': '123 Test Street',
      'amount_paid': 3000,
      'escrow_amount': 2000,
      'commission_amount': 1000,
      'status': 'paid',
    }).select();
    
    print('Job created: $job');
  } catch (e) {
    print('Error creating job: $e');
  }
}
