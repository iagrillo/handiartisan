import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class EquipmentRentalCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String rateType;
  final bool operatorIncluded;
  final String location;
  final bool availableNow;
  final bool instantBooking;
  final bool deliveryAvailable;
  final bool lowDeposit;
  final bool topRated;
  final VoidCallback? onRentNow;

  const EquipmentRentalCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.rateType,
    this.operatorIncluded = false,
    required this.location,
    this.availableNow = false,
    this.instantBooking = false,
    this.deliveryAvailable = false,
    this.lowDeposit = false,
    this.topRated = false,
    this.onRentNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              child: Image.network(
                imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: AppTheme.inputFill,
                  child: Icon(Icons.image, size: 40, color: AppTheme.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text('$price / $rateType', style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: AppTheme.spaceXXS),
                  if (operatorIncluded)
                    Text('Operator Included', style: AppTheme.bodySmall.copyWith(color: AppTheme.success)),
                  Text(location, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: AppTheme.spaceXXS),
                  if (availableNow)
                    Text('Available Now', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                  const SizedBox(height: AppTheme.spaceSM),
                  Wrap(
                    spacing: AppTheme.spaceSM,
                    runSpacing: AppTheme.spaceXXS,
                    children: [
                      if (instantBooking)
                        Chip(
                          label: const Text('Instant Booking', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.success.withOpacity(0.1),
                          avatar: Icon(Icons.flash_on, color: AppTheme.success, size: 16),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (deliveryAvailable)
                        Chip(
                          label: const Text('Delivery Available', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          avatar: Icon(Icons.local_shipping, color: AppTheme.primary, size: 16),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (lowDeposit)
                        Chip(
                          label: const Text('Low Deposit', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.warning.withOpacity(0.1),
                          avatar: Icon(Icons.savings, color: AppTheme.warning, size: 16),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (topRated)
                        Chip(
                          label: const Text('Top Rated', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.info.withOpacity(0.1),
                          avatar: Icon(Icons.star, color: AppTheme.info, size: 16),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: onRentNow,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: AppTheme.spaceSM),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        backgroundColor: AppTheme.primary,
                      ),
                      child: const Text('Rent Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
