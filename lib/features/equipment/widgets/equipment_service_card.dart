import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class EquipmentServiceCard extends StatelessWidget {
  final String title;
  final String specialty;
  final String location;
  final double rating;
  final int reviews;
  final String responseTime;
  final VoidCallback? onRequestService;

  const EquipmentServiceCard({
    Key? key,
    required this.title,
    required this.specialty,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.responseTime,
    this.onRequestService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS),
            Text(specialty, style: AppTheme.bodySmall.copyWith(color: AppTheme.warning)),
            Text(location, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                Icon(Icons.star, color: AppTheme.ratingStar, size: 16),
                const SizedBox(width: AppTheme.spaceXXS),
                Text(rating.toStringAsFixed(1), style: AppTheme.bodySmall),
                const SizedBox(width: AppTheme.spaceSM),
                Text('($reviews reviews)', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(width: AppTheme.spaceMD),
                Icon(Icons.flash_on, color: AppTheme.success, size: 16),
                const SizedBox(width: AppTheme.spaceXXS),
                Text('Responds in $responseTime', style: AppTheme.bodySmall.copyWith(color: AppTheme.success)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onRequestService,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: AppTheme.spaceSM),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  backgroundColor: AppTheme.warning,
                ),
                child: const Text('Request Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
