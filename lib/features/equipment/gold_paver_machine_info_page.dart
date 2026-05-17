import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldPaverMachineInfoPage extends StatelessWidget {
  const GoldPaverMachineInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paver Machine Info')),
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
                      child: SafeAssetImage(assetPath: 'assets/equipment5.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment5.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Paver Machine', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Precision paver machine for road and surface construction.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• Accurate paving', style: AppTheme.bodyMedium),
              const Text('• Easy operation', style: AppTheme.bodyMedium),
              const Text('• Low maintenance', style: AppTheme.bodyMedium),
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
