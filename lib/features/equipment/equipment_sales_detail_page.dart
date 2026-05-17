import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentSalesDetailPage extends StatelessWidget {
  final List<String> galleryImages;
  final String title;
  final String price;
  final String sellerName;
  final String sellerProfileImage;
  final Map<String, String> specifications;
  final String conditionReport;
  final String year;
  final String hoursUsed;
  final List<String> deliveryOptions;
  final bool financeAvailable;
  final VoidCallback? onChat;
  final VoidCallback? onCall;
  final VoidCallback? onMakeOffer;

  const EquipmentSalesDetailPage({
    Key? key,
    required this.galleryImages,
    required this.title,
    required this.price,
    required this.sellerName,
    required this.sellerProfileImage,
    required this.specifications,
    required this.conditionReport,
    required this.year,
    required this.hoursUsed,
    required this.deliveryOptions,
    this.financeAvailable = false,
    this.onChat,
    this.onCall,
    this.onMakeOffer,
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
                      child: Icon(Icons.image,
                          size: 60, color: AppTheme.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text(price,
                style: AppTheme.headline3.copyWith(color: AppTheme.primary)),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(sellerProfileImage),
                  radius: 22,
                  backgroundColor: AppTheme.inputFill,
                ),
                const SizedBox(width: AppTheme.spaceMD + 2),
                Text(sellerName, style: AppTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Specifications', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Table(
              columnWidths: const {0: IntrinsicColumnWidth()},
              children: specifications.entries.map((e) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceXS),
                      child: Text('${e.key}:', style: AppTheme.labelLarge),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceXS),
                      child: Text(e.value),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Condition Report', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Text(conditionReport),
            const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                Text('Year: ', style: AppTheme.labelLarge),
                Text(year),
                const SizedBox(width: AppTheme.spaceXL),
                Text('Hours Used: ', style: AppTheme.labelLarge),
                Text(hoursUsed),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Delivery Options', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spaceXS + 2),
            Wrap(
              spacing: AppTheme.spaceSM,
              children:
                  deliveryOptions.map((opt) => Chip(label: Text(opt))).toList(),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            if (financeAvailable)
              Row(
                children: [
                  Icon(Icons.attach_money, color: AppTheme.success),
                  const SizedBox(width: AppTheme.spaceXS + 2),
                  Text('Finance option available (future revenue)',
                      style: AppTheme.labelLarge
                          .copyWith(color: AppTheme.success)),
                ],
              ),
            if (financeAvailable) const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsapp,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                ElevatedButton(
                  onPressed: onMakeOffer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning),
                  child: const Text('Make Offer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
