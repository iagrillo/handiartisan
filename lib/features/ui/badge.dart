import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UIBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const UIBadge({
    required this.label,
    this.color,
    this.icon,
    this.textStyle,
    this.padding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.primary;
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSM + 2,
            vertical: AppTheme.spaceXS + 1,
          ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: badgeColor, size: 14),
            const SizedBox(width: AppTheme.spaceXS),
          ],
          Text(
            label,
            style: textStyle ??
                TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
