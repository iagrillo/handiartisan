import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentPartsFilterSheet extends StatefulWidget {
  final void Function()? onApply;
  const EquipmentPartsFilterSheet({Key? key, this.onApply}) : super(key: key);

  @override
  State<EquipmentPartsFilterSheet> createState() => _EquipmentPartsFilterSheetState();
}

class _EquipmentPartsFilterSheetState extends State<EquipmentPartsFilterSheet> {
  String? _partType;
  String? _brand;
  String? _equipmentModel;
  String _oemType = 'OEM';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  bool _inStock = false;
  String _deliverySpeed = 'Any';

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
                Text('Parts Filters', style: AppTheme.headline3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Part Type'),
              value: _partType,
              items: [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'Hydraulic Filter', child: Text('Hydraulic Filter')),
                DropdownMenuItem(value: 'Oil Filter', child: Text('Oil Filter')),
                DropdownMenuItem(value: 'Fuel Pump', child: Text('Fuel Pump')),
                DropdownMenuItem(value: 'Alternator', child: Text('Alternator')),
                DropdownMenuItem(value: 'Starter Motor', child: Text('Starter Motor')),
              ],
              onChanged: (val) => setState(() => _partType = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Brand'),
              value: _brand,
              items: [
                DropdownMenuItem(value: null, child: Text('All Brands')),
                DropdownMenuItem(value: 'CAT', child: Text('CAT')),
                DropdownMenuItem(value: 'Komatsu', child: Text('Komatsu')),
                DropdownMenuItem(value: 'JCB', child: Text('JCB')),
                DropdownMenuItem(value: 'John Deere', child: Text('John Deere')),
              ],
              onChanged: (val) => setState(() => _brand = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Equipment Model'),
              value: _equipmentModel,
              items: [
                DropdownMenuItem(value: null, child: Text('All Models')),
                DropdownMenuItem(value: '320D', child: Text('320D')),
                DropdownMenuItem(value: 'D6R', child: Text('D6R')),
                DropdownMenuItem(value: 'WA380', child: Text('WA380')),
                DropdownMenuItem(value: 'JS220', child: Text('JS220')),
              ],
              onChanged: (val) => setState(() => _equipmentModel = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'OEM / Aftermarket'),
              value: _oemType,
              items: [
                DropdownMenuItem(value: 'OEM', child: Text('OEM')),
                DropdownMenuItem(value: 'Aftermarket', child: Text('Aftermarket')),
              ],
              onChanged: (val) => setState(() => _oemType = val ?? 'OEM'),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text('Price Range', style: AppTheme.labelLarge),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 1000000,
              divisions: 100,
              labels: RangeLabels(
                '₦${_priceRange.start.toStringAsFixed(0)}',
                '₦${_priceRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            CheckboxListTile(
              value: _inStock,
              onChanged: (val) => setState(() => _inStock = val ?? false),
              title: const Text('In Stock'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Delivery Speed'),
              value: _deliverySpeed,
              items: [
                DropdownMenuItem(value: 'Any', child: Text('Any')),
                DropdownMenuItem(value: '24hrs', child: Text('Ships in 24hrs')),
                DropdownMenuItem(value: '3 days', child: Text('Ships in 3 days')),
                DropdownMenuItem(value: '1 week', child: Text('Ships in 1 week')),
              ],
              onChanged: (val) => setState(() => _deliverySpeed = val ?? 'Any'),
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
