import 'package:flutter/material.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../../models/artisan.dart';
import '../../ui/app_theme.dart';
import '../artisan_profile_page.dart';

class ArtisanCard extends StatelessWidget {
  final Artisan artisan;
  final double? userLat;
  final double? userLng;
  final bool sponsoredStyling;
  final bool showSponsoredBadge;

  const ArtisanCard({
    Key? key,
    required this.artisan,
    this.userLat,
    this.userLng,
    this.sponsoredStyling = false,
    this.showSponsoredBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? distanceKm;
    if (userLat != null &&
        userLng != null &&
        artisan.latitude != null &&
        artisan.longitude != null) {
      const double earthRadius = 6371;
      double dLat = (artisan.latitude! - userLat!) * 3.141592653589793 / 180.0;
      double dLng = (artisan.longitude! - userLng!) * 3.141592653589793 / 180.0;
      double a = (sin(dLat / 2) * sin(dLat / 2)) +
          cos(userLat! * 3.141592653589793 / 180.0) *
              cos(artisan.latitude! * 3.141592653589793 / 180.0) *
              (sin(dLng / 2) * sin(dLng / 2));
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      distanceKm = earthRadius * c;
    }

    final cardColor = sponsoredStyling
        ? AppTheme.primary.withOpacity(0.035)
        : AppTheme.cardBackground;
    final borderColor = sponsoredStyling
        ? AppTheme.primary.withOpacity(0.18)
        : AppTheme.divider;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          AppTheme.fadeRoute(ArtisanProfilePage(artisan: artisan)),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceBase),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: AppTheme.shadowSM,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.inputFill,
                    backgroundImage: (artisan.profileImageUrl != null &&
                            artisan.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(artisan.profileImageUrlWithCache ??
                            artisan.profileImageUrl!)
                        : null,
                    child: (artisan.profileImageUrl == null ||
                            artisan.profileImageUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            size: 24, color: AppTheme.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (artisan.businessName != null &&
                                  artisan.businessName!.isNotEmpty)
                              ? artisan.businessName!
                              : (artisan.fullName.isNotEmpty
                                  ? artisan.fullName
                                  : 'Unknown'),
                          style: AppTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((artisan.city != null && artisan.city!.isNotEmpty) ||
                            (artisan.state != null && artisan.state!.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [
                                if (artisan.city != null &&
                                    artisan.city!.isNotEmpty)
                                  artisan.city,
                                if (artisan.state != null &&
                                    artisan.state!.isNotEmpty)
                                  artisan.state
                              ].whereType<String>().join(', '),
                              style: AppTheme.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Wrap(
                          spacing: AppTheme.spaceXS,
                          runSpacing: AppTheme.spaceXXS,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceSM + 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.categoryBadgeBg,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                artisan.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: AppTheme.categoryBadgeText,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceSM + 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: (artisan.isAvailable ?? false)
                                    ? AppTheme.statusAvailable.withOpacity(0.1)
                                    : AppTheme.statusBusy.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                (artisan.isAvailable ?? false)
                                    ? 'Available'
                                    : 'Busy',
                                style: TextStyle(
                                  color: (artisan.isAvailable ?? false)
                                      ? AppTheme.statusAvailable
                                      : AppTheme.statusBusy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spaceSM + 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_outlined,
                                      size: 10,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${distanceKm.toStringAsFixed(1)}km',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Column(
                    children: [
                      _ActionPill(
                        icon: Icons.phone_outlined,
                        label: 'Call',
                        color: AppTheme.success,
                        enabled: artisan.phone.isNotEmpty,
                        onTap: artisan.phone.isNotEmpty
                            ? () async {
                                final url = Uri.parse('tel:${artisan.phone}');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      _ActionPill(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                        color: AppTheme.whatsapp,
                        enabled: (artisan.whatsapp != null &&
                            artisan.whatsapp!.isNotEmpty),
                        onTap: (artisan.whatsapp != null &&
                                artisan.whatsapp!.isNotEmpty)
                            ? () async {
                                String phone = artisan.whatsapp ?? '';
                                phone = phone.replaceAll(RegExp(r'\D'), '');
                                if (!phone.startsWith('234')) {
                                  if (phone.startsWith('0')) {
                                    phone = '234${phone.substring(1)}';
                                  } else if (phone.length == 10) {
                                    phone = '234$phone';
                                  }
                                }
                                final url = Uri.parse(
                                  'https://wa.me/$phone?text=Hello',
                                );
                                try {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {}
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showSponsoredBadge)
            Positioned(
              top: AppTheme.spaceSM,
              left: AppTheme.spaceSM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: AppTheme.spaceXXS + 1,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.14),
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
            ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSM,
          vertical: AppTheme.spaceXXS + 2,
        ),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : AppTheme.inputFill,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: enabled ? color.withOpacity(0.25) : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: enabled ? color : AppTheme.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: enabled ? color : AppTheme.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
