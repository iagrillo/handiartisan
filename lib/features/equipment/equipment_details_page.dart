import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/app_theme.dart';

class EquipmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> equipment;

  const EquipmentDetailsPage({Key? key, required this.equipment})
      : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber,
      {String? equipmentName}) async {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '234${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('234') && cleanNumber.length == 10) {
      cleanNumber = '234$cleanNumber';
    }

    final message = (equipmentName != null && equipmentName.trim().isNotEmpty)
        ? 'Hello, I am interested in your $equipmentName on HandiArtisan.'
        : 'Hello, I am interested in your equipment listing on HandiArtisan.';
    final uri = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (equipment['image_url'] ?? '').toString();
    final name = (equipment['name'] ?? equipment['title'] ?? '').toString();
    final brand = (equipment['brand'] ?? '').toString();
    final price = (equipment['price'] ?? '').toString();
    final description = (equipment['description'] ?? '').toString();
    final condition =
        (equipment['condition'] ?? equipment['type'] ?? '').toString();
    final location =
        '${equipment['city'] ?? ''}, ${equipment['state'] ?? ''}'.trim();
    final seller =
        (equipment['contact_name'] ?? equipment['seller'] ?? '').toString();
    final phone =
        (equipment['phone'] ?? equipment['contact_phone'] ?? '').toString();
    final rating = (equipment['rating'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Equipment Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 200,
                  color: AppTheme.inputFill,
                  child:
                      Icon(Icons.image, size: 60, color: AppTheme.textTertiary),
                ),
              )
            else
              Container(
                height: 200,
                color: AppTheme.inputFill,
                child:
                    Icon(Icons.image, size: 60, color: AppTheme.textTertiary),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      '$name - $brand',
                      style: AppTheme.headline3,
                    )
                  else
                    Text(
                      name,
                      style: AppTheme.headline3,
                    ),
                  const SizedBox(height: AppTheme.spaceSM),
                  if (price.isNotEmpty)
                    Text(
                      price,
                      style:
                          AppTheme.headline2.copyWith(color: AppTheme.primary),
                    ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.ratingStar, size: 20),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(rating.toStringAsFixed(1),
                          style: AppTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  if (condition.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text('Condition: $condition',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  const SizedBox(height: AppTheme.spaceSM),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: AppTheme.spaceSM),
                        Expanded(
                            child: Text(location,
                                style: AppTheme.bodyMedium
                                    .copyWith(color: AppTheme.textSecondary))),
                      ],
                    ),
                  const SizedBox(height: AppTheme.spaceBase),
                  const Divider(),
                  const SizedBox(height: AppTheme.spaceBase),
                  if (description.isNotEmpty) ...[
                    Text('Description', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(description, style: AppTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spaceBase),
                  ],
                  const Divider(),
                  const SizedBox(height: AppTheme.spaceBase),
                  if (seller.isNotEmpty) ...[
                    Text('Seller Information', style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.spaceSM),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text(seller, style: AppTheme.bodyMedium),
                      ],
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text(phone, style: AppTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: AppTheme.spaceXL),
                  if (phone.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(phone),
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spaceMD),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openWhatsApp(phone, equipmentName: name),
                            icon: const Icon(Icons.chat),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spaceMD),
                              backgroundColor: AppTheme.whatsapp,
                            ),
                          ),
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
