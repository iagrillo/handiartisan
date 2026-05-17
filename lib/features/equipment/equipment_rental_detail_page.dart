import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentRentalDetailPage extends StatelessWidget {
  final List<String> galleryImages;
  final String title;
  final String price;
  final String rateType;
  final String depositAmount;
  final String location;
  final bool operatorIncluded;
  final List<DateTimeRange> availability;
  final String damagePolicy;
  final String insurancePolicy;
  final bool escrowNotice;
  final VoidCallback? onBookNow;

  const EquipmentRentalDetailPage({
    Key? key,
    required this.galleryImages,
    required this.title,
    required this.price,
    required this.rateType,
    required this.depositAmount,
    required this.location,
    this.operatorIncluded = false,
    required this.availability,
    required this.damagePolicy,
    required this.insurancePolicy,
    this.escrowNotice = false,
    this.onBookNow,
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
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: galleryImages.length,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  child: Image.network(
                    galleryImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.inputFill,
                      child: Icon(Icons.image, size: 60, color: AppTheme.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('$price / $rateType', style: AppTheme.headline3.copyWith(color: AppTheme.primary)),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Deposit: $depositAmount', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spaceSM),
            Text('Location: $location', style: AppTheme.bodyLarge),
            const SizedBox(height: AppTheme.spaceSM),
            if (operatorIncluded)
              Text('Operator Included', style: AppTheme.bodyMedium.copyWith(color: AppTheme.success)),
            const SizedBox(height: AppTheme.spaceMD),
            Text('Availability', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            ...availability.map((range) => Text('${range.start.toLocal()} - ${range.end.toLocal()}')),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Damage Policy', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Text(damagePolicy),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Insurance Policy', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Text(insurancePolicy),
            const SizedBox(height: AppTheme.spaceBase),
            if (escrowNotice)
              Row(
                children: [
                  Icon(Icons.lock, color: AppTheme.warning),
                  const SizedBox(width: AppTheme.spaceXS + 2),
                  Text('Escrow payment will be held until rental is complete.',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.warning)),
                ],
              ),
            if (escrowNotice) const SizedBox(height: AppTheme.spaceBase),
            Center(
              child: ElevatedButton(
                onPressed: onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2XL, vertical: AppTheme.spaceMD),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
