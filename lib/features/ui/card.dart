import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UICard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  const UICard({
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.padding,
    this.elevated = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: elevated ? null : Border.all(color: AppTheme.divider, width: 1),
        boxShadow: elevated ? AppTheme.shadowMD : AppTheme.shadowSM,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: AppTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spaceXXS),
                Text(subtitle!, style: AppTheme.bodySmall),
              ],
              const SizedBox(height: AppTheme.spaceSM),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              Row(children: actions!),
              const SizedBox(height: AppTheme.spaceSM),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
