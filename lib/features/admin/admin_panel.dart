import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel', style: AppTheme.titleMedium)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 48, color: AppTheme.primary),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Admin Controls Coming Soon', style: AppTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
