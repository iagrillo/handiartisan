import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class Badge extends StatelessWidget {
  final String label;
  const Badge({required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Text(label, style: AppTheme.labelSmall.copyWith(color: Colors.white)),
    );
  }
}
