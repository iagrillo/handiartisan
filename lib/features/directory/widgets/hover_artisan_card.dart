import 'package:flutter/material.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:handihub_artisan_app/features/models/artisan.dart';
import '../artisan_profile_page.dart';
import '../../ui/app_theme.dart';

/// A beautiful hover card that reveals dynamic content when hovered over
/// Features smooth animations, gradient overlays, and rich content display
class HoverArtisanCard extends StatefulWidget {
  final Artisan artisan;
  final double? userLat;
  final double? userLng;

  const HoverArtisanCard({
    Key? key,
    required this.artisan,
    this.userLat,
    this.userLng,
  }) : super(key: key);

  @override
  State<HoverArtisanCard> createState() => _HoverArtisanCardState();
}

class _HoverArtisanCardState extends State<HoverArtisanCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;
    
    // Calculate distance
    double? distanceKm;
    if (widget.artisan.showDistance == true &&
        widget.artisan.latitude != null &&
        widget.artisan.longitude != null &&
        widget.userLat != null &&
        widget.userLng != null) {
      const double earthRadius = 6371;
      double dLat = (widget.artisan.latitude! - widget.userLat!) * pi / 180.0;
      double dLng = (widget.artisan.longitude! - widget.userLng!) * pi / 180.0;
      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(widget.userLat! * pi / 180.0) *
              cos(widget.artisan.latitude! * pi / 180.0) *
              sin(dLng / 2) * sin(dLng / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      distanceKm = earthRadius * c;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArtisanProfilePage(artisan: widget.artisan),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: _isHovered ? AppTheme.shadowLG : AppTheme.shadowMD,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  height: _isHovered ? 280 : 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isHovered
                          ? [
                              AppTheme.primary,
                              AppTheme.primaryDark,
                            ]
                          : [
                              AppTheme.surface,
                              AppTheme.inputFill,
                            ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(isSmall ? AppTheme.spaceMD : AppTheme.spaceBase),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section (always visible)
                      _buildHeader(isSmall, distanceKm),
                      SizedBox(height: isSmall ? AppTheme.spaceSM : AppTheme.spaceMD),
                      // Revealed content on hover
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isHovered
                            ? _buildExpandedContent(isSmall)
                            : _buildCompactContent(isSmall),
                      ),
                    ],
                  ),
                ),
                // Hover indicator
                Positioned(
                  top: AppTheme.spaceSM,
                  right: AppTheme.spaceSM,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, size: 12, color: Colors.white),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            'Tap for details',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall, double? distanceKm) {
    return Row(
      children: [
        // Profile image with status indicator
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(_isHovered ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: _isHovered ? 3 : 0,
                ),
              ),
              child: CircleAvatar(
                radius: isSmall ? 22 : 28,
                backgroundColor: AppTheme.inputFill,
                backgroundImage: (widget.artisan.profileImageUrl != null &&
                        widget.artisan.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(widget.artisan.profileImageUrlWithCache ?? widget.artisan.profileImageUrl!)
                    : null,
                child: (widget.artisan.profileImageUrl == null ||
                        widget.artisan.profileImageUrl!.isEmpty)
                    ? Icon(Icons.person, size: isSmall ? 24 : 30, color: AppTheme.textTertiary)
                    : null,
              ),
            ),
            // Availability indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isHovered ? 16 : 12,
                height: _isHovered ? 16 : 12,
                decoration: BoxDecoration(
                  color: widget.artisan.isAvailable == true ? AppTheme.success : AppTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: isSmall ? AppTheme.spaceSM + 2 : AppTheme.spaceMD + 2),
        // Name and category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.artisan.businessName?.isNotEmpty == true
                    ? widget.artisan.businessName!
                    : widget.artisan.fullName,
                style: AppTheme.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 14 : 16,
                  color: _isHovered ? Colors.white : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: isSmall ? 11 : 13,
                    color: _isHovered ? Colors.white70 : AppTheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Flexible(
                    child: Text(
                      widget.artisan.category ?? '',
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: isSmall ? 10 : 12,
                        color: _isHovered ? Colors.white70 : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!_isHovered) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: isSmall ? 11 : 13,
                      color: _isHovered ? Colors.white70 : AppTheme.error,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        [
                          if (widget.artisan.city != null &&
                              widget.artisan.city!.isNotEmpty)
                            widget.artisan.city,
                          if (widget.artisan.state != null &&
                              widget.artisan.state!.isNotEmpty)
                            widget.artisan.state,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: AppTheme.caption.copyWith(
                          fontSize: isSmall ? 9 : 11,
                          color: _isHovered ? Colors.white70 : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Distance and quick actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS + 2, vertical: 2),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.spaceSM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me,
                      size: isSmall ? 10 : 12,
                      color: _isHovered ? Colors.white : AppTheme.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: isSmall ? 9 : 11,
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? Colors.white : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.spaceXS),
            // Quick action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.artisan.phone.isNotEmpty)
                  _buildQuickActionButton(
                    icon: Icons.phone,
                    color: AppTheme.success,
                    isSmall: isSmall,
                    onTap: () async {
                      final url = 'tel:${widget.artisan.phone}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                if (widget.artisan.whatsapp != null &&
                    widget.artisan.whatsapp!.isNotEmpty)
                  _buildQuickActionButton(
                    icon: Icons.chat,
                    color: AppTheme.whatsapp,
                    isSmall: isSmall,
                    onTap: () async {
                      final url = 'https://wa.me/${widget.artisan.whatsapp}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: AppTheme.spaceXS),
        padding: EdgeInsets.all(isSmall ? AppTheme.spaceXS + 2 : AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.spaceSM),
        ),
        child: Icon(
          icon,
          size: isSmall ? 14 : 16,
          color: _isHovered ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildCompactContent(bool isSmall) {
    return Row(
      children: [
        // Rating stars
        _buildRatingStars(isSmall),
        const SizedBox(width: AppTheme.spaceSM),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: 3),
          decoration: BoxDecoration(
            color: widget.artisan.isAvailable == true
                ? AppTheme.success.withOpacity(0.15)
                : AppTheme.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Text(
            widget.artisan.isAvailable == true ? 'Available' : 'Busy',
            style: AppTheme.labelSmall.copyWith(
              color: widget.artisan.isAvailable == true ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 10 : 11,
            ),
          ),
        ),
        const Spacer(),
        // Arrow indicator
        Icon(
          Icons.keyboard_arrow_down,
          color: AppTheme.textTertiary,
          size: isSmall ? 16 : 20,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spaceSM),
        // Divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        // Location
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.white70),
            const SizedBox(width: AppTheme.spaceXS),
            Expanded(
              child: Text(
                [
                  if (widget.artisan.address != null &&
                      widget.artisan.address!.isNotEmpty)
                    widget.artisan.address,
                  if (widget.artisan.city != null &&
                      widget.artisan.city!.isNotEmpty)
                    widget.artisan.city,
                  if (widget.artisan.state != null &&
                      widget.artisan.state!.isNotEmpty)
                    widget.artisan.state,
                ].where((e) => e != null && e.isNotEmpty).join(', '),
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: isSmall ? 11 : 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM + 2),
        // Bio
        if (widget.artisan.bio != null && widget.artisan.bio!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white70),
              const SizedBox(width: AppTheme.spaceXS + 2),
              Expanded(
                child: Text(
                  widget.artisan.bio!,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: isSmall ? 11 : 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM + 2),
        ],
        // Gallery preview if available
        if (widget.artisan.galleryImageUrls?.isNotEmpty == true) ...[
          Row(
            children: [
              const Icon(Icons.photo_library, size: 14, color: Colors.white70),
              const SizedBox(width: AppTheme.spaceXS + 2),
              Text(
                'Gallery: ${widget.artisan.galleryImageUrls?.length ?? 0} images',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white70,
                  fontSize: isSmall ? 11 : 12,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              // Mini gallery preview
              ...?widget.artisan.galleryImageUrls?.take(3).map((url) => 
                Container(
                  margin: const EdgeInsets.only(right: AppTheme.spaceXS),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.spaceXS),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if ((widget.artisan.galleryImageUrls?.length ?? 0) > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.spaceXS),
                  ),
                  child: Text(
                    '+${(widget.artisan.galleryImageUrls?.length ?? 0) - 3}',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM + 2),
        ],
        // Action buttons row
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone,
                label: 'Call',
                color: AppTheme.success,
                isSmall: isSmall,
                onTap: () async {
                  final url = 'tel:${widget.artisan.phone}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: AppTheme.whatsapp,
                isSmall: isSmall,
                onTap: () async {
                  final url = 'https://wa.me/${widget.artisan.whatsapp}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person,
                label: 'Profile',
                color: AppTheme.primary,
                isSmall: isSmall,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ArtisanProfilePage(artisan: widget.artisan),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingStars(bool isSmall) {
    final rating = widget.artisan.rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;
        
        if (rating != null && rating >= starValue) {
          icon = Icons.star;
          color = AppTheme.ratingStar;
        } else if (rating != null && rating >= starValue - 0.5) {
          icon = Icons.star_half;
          color = AppTheme.ratingStar;
        } else {
          icon = Icons.star_border;
          color = AppTheme.textTertiary;
        }
        
        return Icon(
          icon,
          size: isSmall ? 12 : 14,
          color: _isHovered ? AppTheme.ratingStar : color,
        );
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? AppTheme.spaceSM : AppTheme.spaceMD,
            vertical: isSmall ? AppTheme.spaceSM : AppTheme.spaceSM + 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isSmall ? 14 : 16, color: Colors.white),
              SizedBox(width: isSmall ? AppTheme.spaceXS : AppTheme.spaceXS + 2),
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 10 : 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
