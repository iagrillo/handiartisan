import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldMobileBatchingPlantInfoPage extends StatelessWidget {
  const GoldMobileBatchingPlantInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Batching Plant Info')),
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
                      child: SafeAssetImage(assetPath: 'assets/equipment1.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment1.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Mobile Batching Plant', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Efficient mobile batching plant for flexible concrete production.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• High mobility and easy setup', style: AppTheme.bodyMedium),
              const Text('• Suitable for remote sites', style: AppTheme.bodyMedium),
              const Text('• Fast batching cycles', style: AppTheme.bodyMedium),
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
