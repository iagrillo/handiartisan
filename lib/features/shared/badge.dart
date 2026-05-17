import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const Badge({
    required this.label,
    this.color = AppTheme.primary,
    this.icon,
    this.textStyle,
    this.padding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            const SizedBox(width: 0),
            Icon(icon, color: AppTheme.surface, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle ?? const TextStyle(color: AppTheme.surface),
          ),
        ],
      ),
    );
  }
}
