import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentSalesFilterSheet extends StatefulWidget {
  final void Function()? onApply;
  const EquipmentSalesFilterSheet({Key? key, this.onApply}) : super(key: key);

  @override
  State<EquipmentSalesFilterSheet> createState() => _EquipmentSalesFilterSheetState();
}

class _EquipmentSalesFilterSheetState extends State<EquipmentSalesFilterSheet> {
  String? _category;
  String? _brand;
  String? _condition;
  RangeValues _priceRange = const RangeValues(0, 1000000);
  String? _location;
  bool _verifiedSeller = false;
  bool _deliveryAvailable = false;
  bool _warrantyAvailable = false;

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
                Text('Filters (Sales)', style: AppTheme.headline3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: _category,
              items: [
                DropdownMenuItem(value: null, child: Text('All Categories')),
                DropdownMenuItem(value: 'Excavators', child: Text('Excavators')),
                DropdownMenuItem(value: 'Bulldozers', child: Text('Bulldozers')),
                DropdownMenuItem(value: 'Loaders', child: Text('Loaders')),
                DropdownMenuItem(value: 'Graders', child: Text('Graders')),
                DropdownMenuItem(value: 'Cranes', child: Text('Cranes')),
                DropdownMenuItem(value: 'Forklifts', child: Text('Forklifts')),
                DropdownMenuItem(value: 'Generators', child: Text('Generators')),
                DropdownMenuItem(value: 'Compressors', child: Text('Compressors')),
                DropdownMenuItem(value: 'Agricultural Equipment', child: Text('Agricultural Equipment')),
                DropdownMenuItem(value: 'Industrial Machines', child: Text('Industrial Machines')),
                DropdownMenuItem(value: 'Construction Tools', child: Text('Construction Tools')),
              ],
              onChanged: (val) => setState(() => _category = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Brand'),
              value: _brand,
              items: [
                DropdownMenuItem(value: null, child: Text('All Brands')),
                DropdownMenuItem(value: 'Caterpillar', child: Text('Caterpillar')),
                DropdownMenuItem(value: 'Komatsu', child: Text('Komatsu')),
                DropdownMenuItem(value: 'JCB', child: Text('JCB')),
                DropdownMenuItem(value: 'John Deere', child: Text('John Deere')),
                DropdownMenuItem(value: 'Liebherr', child: Text('Liebherr')),
              ],
              onChanged: (val) => setState(() => _brand = val),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Condition'),
              value: _condition,
              items: [
                DropdownMenuItem(value: null, child: Text('Any Condition')),
                DropdownMenuItem(value: 'New', child: Text('New')),
                DropdownMenuItem(value: 'Used', child: Text('Used')),
              ],
              onChanged: (val) => setState(() => _condition = val),
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
            const SizedBox(height: AppTheme.spaceMD),
            CheckboxListTile(
              value: _verifiedSeller,
              onChanged: (val) => setState(() => _verifiedSeller = val ?? false),
              title: const Text('Verified Seller'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _deliveryAvailable,
              onChanged: (val) => setState(() => _deliveryAvailable = val ?? false),
              title: const Text('Delivery Available'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _warrantyAvailable,
              onChanged: (val) => setState(() => _warrantyAvailable = val ?? false),
              title: const Text('Warranty Available'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
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
