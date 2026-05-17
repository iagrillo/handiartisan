import 'package:flutter/material.dart';
import '../../models/artisan.dart';
import '../../ui/app_theme.dart';
import '../artisan_profile_page.dart';

class FeaturedArtisanCarousel extends StatefulWidget {
  final List<Artisan> featuredArtisans;

  const FeaturedArtisanCarousel({
    Key? key,
    required this.featuredArtisans,
  }) : super(key: key);

  @override
  State<FeaturedArtisanCarousel> createState() =>
      _FeaturedArtisanCarouselState();
}

class _FeaturedArtisanCarouselState extends State<FeaturedArtisanCarousel> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: AppTheme.spaceXS),
                Text('Featured Artisans (Sponsored)', style: AppTheme.titleSmall),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.featuredArtisans.length,
              itemBuilder: (context, index) {
                final artisan = widget.featuredArtisans[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      AppTheme.fadeRoute(ArtisanProfilePage(artisan: artisan)),
                    );
                  },
                  child: Container(
                    width: 154,
                    margin: EdgeInsets.only(
                      right: index == widget.featuredArtisans.length - 1
                          ? 0
                          : AppTheme.spaceSM,
                    ),
                    padding: const EdgeInsets.all(AppTheme.spaceSM),
                    decoration: BoxDecoration(
                      gradient: AppTheme.subtleGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: AppTheme.shadowSM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.25),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.inputFill,
                                backgroundImage: artisan.profileImageUrl != null &&
                                        artisan.profileImageUrl!.isNotEmpty
                                    ? NetworkImage(
                                        artisan.profileImageUrlWithCache ?? artisan.profileImageUrl!,
                                      )
                                    : null,
                                child: artisan.profileImageUrl == null || artisan.profileImageUrl!.isEmpty
                                    ? const Icon(Icons.person, size: 20, color: AppTheme.textTertiary)
                                    : null,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceSM,
                                vertical: AppTheme.spaceXXS + 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                'Sponsored',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceSM),
                        Text(
                          artisan.businessName?.isNotEmpty == true ? artisan.businessName! : artisan.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleSmall,
                        ),
                        const SizedBox(height: AppTheme.spaceXXS),
                        Text(
                          artisan.category.isNotEmpty ? artisan.category : 'Artisan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                artisan.city?.isNotEmpty == true ? artisan.city! : 'Location not set',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.caption,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceXXS),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.ratingStar),
                            const SizedBox(width: 4),
                            Text(
                              (artisan.rating ?? 4.5).toStringAsFixed(1),
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
