import 'package:flutter/material.dart';
import '../../utils/asset_image.dart';
import '../../ui/app_theme.dart';

class GoldRMCCard extends StatelessWidget {
  final VoidCallback onTap;
  const GoldRMCCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border.all(color: Colors.amber.shade700, width: 2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              child: SafeAssetImage(
                assetPath: 'assets/rmc.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('RMC Concrete Batching Plant',
                      style: AppTheme.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Ready-mix concrete batching plant for high-volume production.',
                      style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceXS),
            Icon(Icons.arrow_forward_ios, color: Colors.amber.shade700, size: 14),
          ],
        ),
      ),
    );
  }
}
