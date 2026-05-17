import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/artisan.dart';
import '../ui/app_theme.dart';
import 'artisan_profile_page.dart';

class ArtisanCard extends StatelessWidget {
  final Artisan artisan;
  final double? userLat;
  final double? userLng;

  const ArtisanCard({
    required this.artisan,
    this.userLat,
    this.userLng,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;
    double? distanceKm;
    if (artisan.latitude != null &&
        artisan.longitude != null &&
        userLat != null &&
        userLng != null) {
      const double earthRadius = 6371; // km
      double dLat = (artisan.latitude! - userLat!) * 3.141592653589793 / 180.0;
      double dLng = (artisan.longitude! - userLng!) * 3.141592653589793 / 180.0;
      double a = (sin(dLat / 2) * sin(dLat / 2)) +
          cos(userLat! * 3.141592653589793 / 180.0) *
              cos(artisan.latitude! * 3.141592653589793 / 180.0) *
              (sin(dLng / 2) * sin(dLng / 2));
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      distanceKm = earthRadius * c;
    }
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: isSmall ? 4 : 12, vertical: isSmall ? 4 : 8),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSmall ? 14 : 22,
                  backgroundColor: AppTheme.divider,
                  backgroundImage: (artisan.profileImageUrl != null &&
                          artisan.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(artisan.profileImageUrlWithCache ??
                          artisan.profileImageUrl!)
                      : null,
                  child: (artisan.profileImageUrl == null ||
                          artisan.profileImageUrl!.isEmpty)
                      ? Icon(Icons.person,
                          size: isSmall ? 18 : 28, color: AppTheme.textTertiary)
                      : null,
                ),
                SizedBox(width: isSmall ? 8 : 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtisanProfilePage(artisan: artisan),
                        ),
                      );
                    },
                    child: Text(
                      artisan.businessName ?? artisan.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 16 : 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (distanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.red, size: isSmall ? 14 : 18),
                        Text('${distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                                fontSize: isSmall ? 11 : 14,
                                color: Colors.red)),
                      ],
                    ),
                  ),
                if (artisan.phone.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.phone,
                        color: Colors.green, size: isSmall ? 18 : 24),
                    tooltip: 'Call',
                    onPressed: () async {
                      final url = 'tel:${artisan.phone}';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                  ),
                if (artisan.whatsapp != null && artisan.whatsapp!.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.chat,
                        color: AppTheme.whatsapp, size: isSmall ? 18 : 24),
                    tooltip: 'WhatsApp',
                    onPressed: () async {
                      final url = 'https://wa.me/${artisan.whatsapp}';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                  ),
              ],
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Text(
              artisan.category,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmall ? 13 : 16,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (artisan.bio != null && artisan.bio!.isNotEmpty) ...[
              SizedBox(height: isSmall ? 4 : 8),
              Text(
                artisan.bio!,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textPrimary.withValues(alpha: 0.88),
                ),
                maxLines: isSmall ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
