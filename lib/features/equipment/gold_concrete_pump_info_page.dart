import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldConcretePumpInfoPage extends StatelessWidget {
  const GoldConcretePumpInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concrete Pump Info'),
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
                      child: SafeAssetImage(assetPath: 'assets/equipment6.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment6.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Concrete Pump', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Efficient and reliable concrete pumping for construction projects.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• High-pressure pumping for long-distance and high-rise applications.', style: AppTheme.bodyMedium),
              const Text('• Robust design for durability and low maintenance.', style: AppTheme.bodyMedium),
              const Text('• Easy operation and safety features.', style: AppTheme.bodyMedium),
              const Text('• Suitable for commercial, industrial, and infrastructure works.', style: AppTheme.bodyMedium),
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
