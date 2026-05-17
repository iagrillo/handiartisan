import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentServiceDetailPage extends StatelessWidget {
  final String technicianName;
  final String profileImage;
  final String about;
  final List<String> certifications;
  final int jobsCompleted;
  final List<String> serviceAreas;
  final String emergencyHotline;
  final VoidCallback? onUploadPhotos;
  final VoidCallback? onRequestQuote;

  const EquipmentServiceDetailPage({
    Key? key,
    required this.technicianName,
    required this.profileImage,
    required this.about,
    required this.certifications,
    required this.jobsCompleted,
    required this.serviceAreas,
    required this.emergencyHotline,
    this.onUploadPhotos,
    this.onRequestQuote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(technicianName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImage),
                  radius: 28,
                  backgroundColor: AppTheme.inputFill,
                ),
                const SizedBox(width: AppTheme.spaceBase - 2),
                Expanded(
                  child: Text(technicianName, style: AppTheme.headline3),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('About', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Text(about),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Certifications', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Wrap(
              spacing: AppTheme.spaceSM,
              children: certifications.map((c) => Chip(label: Text(c))).toList(),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Jobs Completed: $jobsCompleted', style: AppTheme.bodyLarge),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Service Areas', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Wrap(
              spacing: AppTheme.spaceSM,
              children: serviceAreas.map((area) => Chip(label: Text(area))).toList(),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Emergency Hotline', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.error),
                const SizedBox(width: AppTheme.spaceXS + 2),
                Text(emergencyHotline, style: AppTheme.labelLarge.copyWith(color: AppTheme.error)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            ElevatedButton.icon(
              onPressed: onUploadPhotos,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Equipment Photos'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Center(
              child: ElevatedButton(
                onPressed: onRequestQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2XL, vertical: AppTheme.spaceMD),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Request Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
