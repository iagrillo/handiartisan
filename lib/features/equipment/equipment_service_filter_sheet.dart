import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentServiceFilterSheet extends StatefulWidget {
  final void Function()? onApply;
  const EquipmentServiceFilterSheet({Key? key, this.onApply}) : super(key: key);

  @override
  State<EquipmentServiceFilterSheet> createState() => _EquipmentServiceFilterSheetState();
}

class _EquipmentServiceFilterSheetState extends State<EquipmentServiceFilterSheet> {
  String? _serviceType;
  String? _equipmentType;
  bool _emergencyAvailable = false;
  String _siteType = 'Onsite';
  double _minRating = 0;
  String? _location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: AppTheme.spaceSM),
                Text('Service Filters', style: AppTheme.headline3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Service Type'),
              value: _serviceType,
              items: [
                DropdownMenuItem(value: null, child: Text('All Services')),
                DropdownMenuItem(value: 'Repair', child: Text('Repair')),
                DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                DropdownMenuItem(value: 'Inspection', child: Text('Inspection')),
                DropdownMenuItem(value: 'Installation', child: Text('Installation')),
              ],
              onChanged: (val) => setState(() => _serviceType = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Equipment Type'),
              value: _equipmentType,
              items: [
                DropdownMenuItem(value: null, child: Text('All Equipment')),
                DropdownMenuItem(value: 'Excavator', child: Text('Excavator')),
                DropdownMenuItem(value: 'Bulldozer', child: Text('Bulldozer')),
                DropdownMenuItem(value: 'Crane', child: Text('Crane')),
                DropdownMenuItem(value: 'Forklift', child: Text('Forklift')),
                DropdownMenuItem(value: 'Generator', child: Text('Generator')),
              ],
              onChanged: (val) => setState(() => _equipmentType = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            CheckboxListTile(
              value: _emergencyAvailable,
              onChanged: (val) => setState(() => _emergencyAvailable = val ?? false),
              title: const Text('Emergency Available'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Site Type'),
              value: _siteType,
              items: [
                DropdownMenuItem(value: 'Onsite', child: Text('Onsite')),
                DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
              ],
              onChanged: (val) => setState(() => _siteType = val ?? 'Onsite'),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              children: [
                const Text('Min Rating:'),
                Expanded(
                  child: Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _minRating.toStringAsFixed(1),
                    onChanged: (val) => setState(() => _minRating = val),
                  ),
                ),
                Text(_minRating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Location'),
              value: _location,
              items: [
                DropdownMenuItem(value: null, child: Text('All Locations')),
                DropdownMenuItem(value: 'Lagos', child: Text('Lagos')),
                DropdownMenuItem(value: 'Abuja', child: Text('Abuja')),
                DropdownMenuItem(value: 'Kano', child: Text('Kano')),
              ],
              onChanged: (val) => setState(() => _location = val),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onApply ?? () => Navigator.of(context).pop(),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
