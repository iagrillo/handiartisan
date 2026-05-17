import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Page', style: AppTheme.titleMedium)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        children: [
          ListTile(
            leading: const Icon(Icons.people, color: AppTheme.primary),
            title: Text('Manage Artisans', style: AppTheme.labelLarge),
            subtitle: Text('Approve, reject, or edit artisan profiles.', style: AppTheme.bodySmall),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: AppTheme.primary),
            title: Text('View Analytics', style: AppTheme.labelLarge),
            subtitle: Text('See platform usage and stats.', style: AppTheme.bodySmall),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
