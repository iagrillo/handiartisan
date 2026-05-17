import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class EquipmentSalesCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String condition;
  final String location;
  final double rating;
  final String seller;
  final bool verified;
  final bool warranty;
  final bool negotiable;
  final bool urgent;
  final VoidCallback? onViewDetails;
  final Map<String, dynamic>? equipment;

  const EquipmentSalesCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.condition,
    required this.location,
    required this.rating,
    required this.seller,
    this.verified = false,
    this.warranty = false,
    this.negotiable = false,
    this.urgent = false,
    this.onViewDetails,
    this.equipment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.spaceXS + 1),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.inputFill,
                  child: Icon(Icons.image, size: 20, color: AppTheme.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onViewDetails,
                    child: Text(title, style: AppTheme.labelMedium.copyWith(color: AppTheme.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: AppTheme.spaceXXS),
                  Text(price, style: AppTheme.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  const SizedBox(height: AppTheme.spaceXXS),
                  Row(
                    children: [
                      Flexible(child: Text(condition, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(' • ', style: AppTheme.caption.copyWith(color: AppTheme.textTertiary)),
                      Flexible(child: Text(location, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXXS),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.ratingStar, size: 10),
                      const SizedBox(width: AppTheme.spaceXXS),
                      Text(rating.toStringAsFixed(1), style: AppTheme.caption),
                      const SizedBox(width: AppTheme.spaceXS),
                      Expanded(child: Text('Seller: $seller', style: AppTheme.caption.copyWith(color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXXS + 1),
                  Wrap(
                    spacing: 3,
                    runSpacing: AppTheme.spaceXXS,
                    children: [
                      if (verified)
                        Chip(
                          label: const Text('Verified', style: TextStyle(fontSize: 8)),
                          backgroundColor: AppTheme.success.withOpacity(0.1),
                          avatar: Icon(Icons.verified, color: AppTheme.success, size: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (warranty)
                        Chip(
                          label: const Text('Warranty', style: TextStyle(fontSize: 8)),
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          avatar: Icon(Icons.security, color: AppTheme.primary, size: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (negotiable)
                        Chip(
                          label: const Text('Negotiable', style: TextStyle(fontSize: 8)),
                          backgroundColor: AppTheme.warning.withOpacity(0.1),
                          avatar: Icon(Icons.handshake, color: AppTheme.warning, size: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (urgent)
                        Chip(
                          label: const Text('Urgent Sale', style: TextStyle(fontSize: 8)),
                          backgroundColor: AppTheme.error.withOpacity(0.1),
                          avatar: Icon(Icons.priority_high, color: AppTheme.error, size: 10),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
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
