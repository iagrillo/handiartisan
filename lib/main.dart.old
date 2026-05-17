import 'package:flutter/material.dart';
import 'features/directory/directory_page.dart';
import 'features/profile/submit_profile.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize(
    url: 'https://awbqkptzknhlvxfboklf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1ODQyMDEsImV4cCI6MjA4NTE2MDIwMX0.eyH9HAXyhDguzRVz9urxDviD7fBZ6azOsSh8K03PVeU',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandiArtisan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DirectoryPage(),
      routes: {
        '/directory': (context) => DirectoryPage(),
        '/profile': (context) => SubmitProfile(),
        '/admin': (context) => AdminDashboard(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
