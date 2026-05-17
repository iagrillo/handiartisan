import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldToraBatchingPlantInfoPage extends StatelessWidget {
  const GoldToraBatchingPlantInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tora Batching Plant'),
        backgroundColor: AppTheme.warning,
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
                      child: SafeAssetImage(assetPath: 'assets/equipment7.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment7.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Tora Batching Plant', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Efficient batching plant for high-volume production.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• High capacity', style: AppTheme.bodyMedium),
              const Text('• Automated controls', style: AppTheme.bodyMedium),
              const Text('• Durable design', style: AppTheme.bodyMedium),
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
