import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldEquipmentInfoPage extends StatelessWidget {
  const GoldEquipmentInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: SafeAssetImage(assetPath: 'assets/equipment8.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment8.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('General Equipment', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Versatile equipment for multiple construction needs.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• Multi-purpose', style: AppTheme.bodyMedium),
              const Text('• Reliable performance', style: AppTheme.bodyMedium),
              const Text('• Easy operation', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              SafeAssetImage(assetPath: 'assets/conmat_logo.png', height: 40),
              const SizedBox(height: AppTheme.spaceSM),
              const Text('Handihub Global Contact:', style: AppTheme.bodySmall),
              const Text('+2347030657708', style: AppTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
