import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentPartsDetailPage extends StatelessWidget {
  final String title;
  final List<String> compatibleModels;
  final String oemNumber;
  final int stockCount;
  final String warranty;
  final double sellerRating;
  final String bulkDiscount;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const EquipmentPartsDetailPage({
    Key? key,
    required this.title,
    required this.compatibleModels,
    required this.oemNumber,
    required this.stockCount,
    required this.warranty,
    required this.sellerRating,
    required this.bulkDiscount,
    this.onAddToCart,
    this.onBuyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compatible Models', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Wrap(
              spacing: AppTheme.spaceSM,
              children: compatibleModels.map((m) => Chip(label: Text(m))).toList(),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('OEM Number: $oemNumber', style: AppTheme.bodyLarge),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Stock: $stockCount', style: AppTheme.bodyLarge),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Warranty: $warranty', style: AppTheme.bodyLarge),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                Icon(Icons.star, color: AppTheme.ratingStar, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Text(sellerRating.toStringAsFixed(1), style: AppTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Bulk Discount: $bulkDiscount', style: AppTheme.bodyLarge.copyWith(color: AppTheme.success)),
            const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
