import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class GoldEquipmentCard extends StatelessWidget {
  final String title;
  const GoldEquipmentCard({
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD - 2, horizontal: AppTheme.spaceMD),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: Center(
          child: Text(
            title,
            style: AppTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
