import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class DynamicEquipmentCard extends StatelessWidget {
  final Map<String, dynamic> equipment;
  final VoidCallback onTap;

  const DynamicEquipmentCard({
    Key? key,
    required this.equipment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = equipment['title'] ?? 'Equipment';
    final String? imageUrl = equipment['image_url'];
    final String listingType = equipment['listing_type'] ?? '';
    final String location = equipment['location'] ?? '';
    final String? price = equipment['price'];
    final String? description = equipment['description'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warning.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Equipment Image
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            // Equipment Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      title,
                      style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 11,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spaceXXS),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    // Price
                    if (price != null && price.isNotEmpty)
                      Text(
                        price,
                        style: AppTheme.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warning,
                        ),
                      ),
                    // Description preview
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: AppTheme.caption.copyWith(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            // Listing Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXXS),
              margin: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: _getListingTypeColor(listingType),
                borderRadius: BorderRadius.circular(AppTheme.spaceXS),
              ),
              child: Text(
                listingType.toUpperCase(),
                style: AppTheme.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.construction,
        size: 32,
        color: AppTheme.warning,
      ),
    );
  }

  Color _getListingTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sale':
        return AppTheme.success;
      case 'rental':
        return AppTheme.primary;
      case 'service':
        return AppTheme.warning;
      case 'part':
        return AppTheme.info;
      default:
        return AppTheme.textTertiary;
    }
  }
}
