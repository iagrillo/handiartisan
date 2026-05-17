import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final dynamic service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final String name = service['name'] ?? '';
    final String state = service['state'] ?? '';
    final String city = service['city'] ?? '';
    final String contactNumber = service['contact_number'] ?? '';
    final String? email = service['email'];
    final String mobility = service['mobility'] ?? '';
    final String? experience = service['experience_summary'];
    final String? certifications = service['certifications'];

    // Get service types
    List<String> serviceTypes = [];
    if (service['service_maintenance'] == true) serviceTypes.add('Maintenance');
    if (service['service_repair'] == true) serviceTypes.add('Repair');
    if (service['service_installation'] == true) serviceTypes.add('Installation');
    if (service['service_diagnostics'] == true) serviceTypes.add('Diagnostics');

    // Get power tools
    List<String> powerTools = [];
    if (service['power_tools_drills'] == true) powerTools.add('Drills');
    if (service['power_tools_grinders'] == true) powerTools.add('Grinders');
    if (service['power_tools_saws'] == true) powerTools.add('Saws');
    if (service['power_tools_sanders'] == true) powerTools.add('Sanders');
    if (service['power_tools_welding'] == true) powerTools.add('Welding');
    if (service['power_tools_other'] != null && service['power_tools_other'].toString().isNotEmpty) {
      powerTools.add(service['power_tools_other']);
    }

    // Get heavy equipment
    List<String> heavyEquipment = [];
    if (service['heavy_equipment_generators'] == true) heavyEquipment.add('Generators');
    if (service['heavy_equipment_compressors'] == true) heavyEquipment.add('Compressors');
    if (service['heavy_equipment_excavators'] == true) heavyEquipment.add('Excavators');
    if (service['heavy_equipment_forklifts'] == true) heavyEquipment.add('Forklifts');
    if (service['heavy_equipment_bulldozers'] == true) heavyEquipment.add('Bulldozers');
    if (service['heavy_equipment_other'] != null && service['heavy_equipment_other'].toString().isNotEmpty) {
      heavyEquipment.add(service['heavy_equipment_other']);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceBase),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Mobility
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTheme.titleSmall.copyWith(color: AppTheme.primary),
                  ),
                ),
                if (mobility.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Text(
                      _getMobilityLabel(mobility),
                      style: AppTheme.labelMedium.copyWith(color: AppTheme.warning),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spaceXS),
                Text(
                  '$city, $state',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),

            // Service Types
            if (serviceTypes.isNotEmpty) ...[
              const Text(
                'Services:',
                style: AppTheme.labelLarge,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: serviceTypes.map((type) => _buildTag(type, AppTheme.primary)).toList(),
              ),
              const SizedBox(height: AppTheme.spaceMD),
            ],

            // Power Tools
            if (powerTools.isNotEmpty) ...[
              const Text(
                'Power Tools:',
                style: AppTheme.labelLarge,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: powerTools.map((tool) => _buildTag(tool, AppTheme.info)).toList(),
              ),
              const SizedBox(height: AppTheme.spaceMD),
            ],

            // Heavy Equipment
            if (heavyEquipment.isNotEmpty) ...[
              const Text(
                'Heavy Equipment:',
                style: AppTheme.labelLarge,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: heavyEquipment.map((eq) => _buildTag(eq, AppTheme.secondary)).toList(),
              ),
              const SizedBox(height: AppTheme.spaceMD),
            ],

            // Experience
            if (experience != null && experience.isNotEmpty) ...[
              Text(
                'Experience: $experience',
                style: AppTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceSM),
            ],

            // Certifications
            if (certifications != null && certifications.isNotEmpty) ...[
              Text(
                'Certifications: $certifications',
                style: AppTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceSM),
            ],

            const Divider(),
            const SizedBox(height: AppTheme.spaceSM),

            // Contact Info and Book Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: AppTheme.primary),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            contactNumber,
                            style: AppTheme.labelLarge.copyWith(color: AppTheme.primary),
                          ),
                        ],
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceXS),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: AppTheme.spaceXS),
                            Expanded(
                              child: Text(
                                email,
                                style: AppTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(contactNumber),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsapp,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceBase, vertical: AppTheme.spaceSM + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getMobilityLabel(String mobility) {
    switch (mobility) {
      case 'mobile':
        return 'Mobile';
      case 'workshop':
        return 'Workshop';
      case 'both':
        return 'Mobile + Workshop';
      default:
        return mobility;
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Clean the phone number - remove any spaces, dashes, or parentheses
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // If the number starts with 0, replace it with 234 (Nigeria country code)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '234${cleanNumber.substring(1)}';
    }
    
    // Add country code if not present
    if (!cleanNumber.startsWith('234')) {
      cleanNumber = '234$cleanNumber';
    }
    
    final String message = 'Good day, I would like to book a job with you';
    final String url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try with wa.me
        final String fallbackUrl = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
