import 'package:flutter/material.dart';
import '../utils/asset_image.dart';
import '../ui/app_theme.dart';

class GoldLargeInfraInfoPage extends StatelessWidget {
  const GoldLargeInfraInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Large Infrastructure Series Info')),
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
                      child: SafeAssetImage(assetPath: 'assets/equipment4.png'),
                    ),
                  );
                },
                child: SafeAssetImage(assetPath: 'assets/equipment4.png', height: 120),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Large Infrastructure Series', style: AppTheme.titleMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('Advanced solutions for large-scale infrastructure projects.', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceMD),
              const Text('• Robust engineering', style: AppTheme.bodyMedium),
              const Text('• High durability', style: AppTheme.bodyMedium),
              const Text('• Customizable options', style: AppTheme.bodyMedium),
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
