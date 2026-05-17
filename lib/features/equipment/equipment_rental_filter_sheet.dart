import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class EquipmentRentalFilterSheet extends StatefulWidget {
  final void Function()? onApply;
  const EquipmentRentalFilterSheet({Key? key, this.onApply}) : super(key: key);

  @override
  State<EquipmentRentalFilterSheet> createState() => _EquipmentRentalFilterSheetState();
}

class _EquipmentRentalFilterSheetState extends State<EquipmentRentalFilterSheet> {
  String? _category;
  String _rateType = 'Daily';
  DateTimeRange? _availability;
  String? _location;
  bool _deliveryIncluded = false;
  bool _operatorIncluded = false;
  bool _depositRequired = false;

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
                Text('Rental Filters', style: AppTheme.headline3),
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
              decoration: const InputDecoration(labelText: 'Rate Type'),
              value: _rateType,
              items: [
                DropdownMenuItem(value: 'Daily', child: Text('Daily Rate')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly Rate')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly Rate')),
              ],
              onChanged: (val) => setState(() => _rateType = val ?? 'Daily'),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Availability Calendar'),
              subtitle: Text(_availability == null ? 'Select dates' : '${_availability!.start.toLocal()} - ${_availability!.end.toLocal()}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _availability = picked);
              },
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
              value: _deliveryIncluded,
              onChanged: (val) => setState(() => _deliveryIncluded = val ?? false),
              title: const Text('Delivery Included'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _operatorIncluded,
              onChanged: (val) => setState(() => _operatorIncluded = val ?? false),
              title: const Text('Operator Included'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _depositRequired,
              onChanged: (val) => setState(() => _depositRequired = val ?? false),
              title: const Text('Deposit Required'),
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
