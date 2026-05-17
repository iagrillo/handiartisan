import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class DirectoryHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Directory Home', style: AppTheme.titleMedium)),
      body: Center(child: Text('Welcome to the Directory!', style: AppTheme.bodyLarge)),
    );
  }
}

class FilterBarExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Category Dropdown
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: null,
                items: [
                  DropdownMenuItem(value: null, child: Text('Category', style: AppTheme.bodyMedium)),
                  DropdownMenuItem<String>(enabled: false, child: Text('--- Example Group ---', style: AppTheme.bodySmall)),
                  DropdownMenuItem<String>(value: 'Example', child: Text('Example', style: AppTheme.bodyMedium)),
                  DropdownMenuItem(enabled: false, child: Text('--- Other ---', style: AppTheme.bodySmall)),
                  DropdownMenuItem(value: 'Other', child: Text('Other (please specify)', style: AppTheme.bodyMedium)),
                ],
                onChanged: (val) {},
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppTheme.spaceSM),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            // State Dropdown
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                value: null,
                items: [
                  DropdownMenuItem(value: null, child: Text('State', style: AppTheme.bodyMedium)),
                  DropdownMenuItem(value: 'State1', child: Text('State1', style: AppTheme.bodyMedium)),
                  DropdownMenuItem(value: 'State2', child: Text('State2', style: AppTheme.bodyMedium)),
                ],
                onChanged: (val) {},
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppTheme.spaceSM),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            // City Dropdown
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<String>(
                value: null,
                items: [
                  DropdownMenuItem(value: null, child: Text('City', style: AppTheme.bodyMedium)),
                  DropdownMenuItem(value: 'City1', child: Text('City1', style: AppTheme.bodyMedium)),
                  DropdownMenuItem(value: 'City2', child: Text('City2', style: AppTheme.bodyMedium)),
                ],
                onChanged: (val) {},
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppTheme.spaceSM),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: Text('Location Off', style: AppTheme.labelMedium.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textTertiary,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceBase - 6, vertical: AppTheme.spaceBase - 6),
                shape: const StadiumBorder(),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: AppTheme.spaceSM),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primary),
              tooltip: 'Refresh',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
