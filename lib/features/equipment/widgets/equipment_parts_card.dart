import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class EquipmentPartsCard extends StatelessWidget {
  final String title;
  final String price;
  final String oemType;
  final bool inStock;
  final String deliverySpeed;
  final VoidCallback? onAddToCart;

  const EquipmentPartsCard({
    Key? key,
    required this.title,
    required this.price,
    required this.oemType,
    this.inStock = false,
    required this.deliverySpeed,
    this.onAddToCart,
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
            Text(price, style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppTheme.warning)),
            const SizedBox(height: AppTheme.spaceXXS),
            Text(oemType, style: AppTheme.bodySmall.copyWith(color: AppTheme.primary)),
            if (inStock)
              Text('In Stock', style: AppTheme.bodySmall.copyWith(color: AppTheme.success)),
            Text(deliverySpeed, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spaceSM),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onAddToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: AppTheme.spaceSM),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  backgroundColor: AppTheme.warning,
                ),
                child: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
