import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/app_theme.dart';

class StoreCard extends StatelessWidget {
  final String logoUrl;
  final String storeName;
  final String subtitle;
  final String city;
  final String state;
  final bool isOpen;
  final String statusLabel;
  final double rating;
  final String? phone;
  final String? whatsapp;
  final VoidCallback? onWhatsapp;
  final VoidCallback? onViewStore;

  const StoreCard({
    Key? key,
    required this.logoUrl,
    required this.storeName,
    required this.subtitle,
    required this.city,
    required this.state,
    this.isOpen = true,
    this.statusLabel = 'Open',
    this.rating = 4.5,
    this.phone,
    this.whatsapp,
    this.onWhatsapp,
    this.onViewStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewStore,
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.divider, width: 1),
          boxShadow: AppTheme.shadowSM,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceBase),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.inputFill,
                backgroundImage:
                    logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                child: logoUrl.isEmpty
                    ? const Icon(Icons.store,
                        size: 20, color: AppTheme.textTertiary)
                    : null,
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: AppTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (city.isNotEmpty || state.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [city, state].where((s) => s.isNotEmpty).join(', '),
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Wrap(
                      spacing: AppTheme.spaceXS,
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
                            subtitle.length > 15
                                ? '${subtitle.substring(0, 15)}...'
                                : subtitle,
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
                            color: isOpen
                                ? AppTheme.statusOpen.withOpacity(0.1)
                                : AppTheme.statusClosed.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: isOpen
                                  ? AppTheme.statusOpen
                                  : AppTheme.statusClosed,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
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
                  if (phone != null && phone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_outlined,
                          color: AppTheme.success, size: 20),
                      tooltip: 'Call',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () async {
                        final url = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  if (whatsapp != null && whatsapp!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppTheme.whatsapp, size: 20),
                      tooltip: 'WhatsApp',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () async {
                        String p = whatsapp ?? '';
                        p = p.replaceAll(RegExp(r'\D'), '');
                        if (!p.startsWith('234')) {
                          if (p.startsWith('0')) {
                            p = '234${p.substring(1)}';
                          } else if (p.length == 10) {
                            p = '234$p';
                          }
                        }
                        final url = Uri.parse('https://wa.me/$p?text=Hello');
                        try {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: AppTheme.ratingStar, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
