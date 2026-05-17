import 'package:flutter/material.dart';

import '../features/ui/app_theme.dart';

class EscrowBadge extends StatelessWidget {
  final String? label;
  final String? amount;
  final bool showSurface;
  final bool compact;
  final bool badgeBelow;
  final bool expandLabel;
  final EdgeInsetsGeometry? padding;

  const EscrowBadge({
    super.key,
    this.label,
    this.amount,
    this.showSurface = false,
    this.compact = false,
    this.badgeBelow = false,
    this.expandLabel = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        (compact ? AppTheme.bodySmall : AppTheme.labelLarge).copyWith(
      color: AppTheme.textSecondary,
      fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
    );

    final amountStyle =
        (compact ? AppTheme.bodySmall : AppTheme.labelLarge).copyWith(
      color: AppTheme.primary,
      fontWeight: FontWeight.w700,
    );

    final badge = Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        'Escrowed',
        style: AppTheme.caption.copyWith(
          color: AppTheme.surface,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : null,
        ),
      ),
    );

    final trailing = badgeBelow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (amount != null) Text(amount!, style: amountStyle),
              if (amount != null) const SizedBox(height: 4),
              badge,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (amount != null) Text(amount!, style: amountStyle),
              if (amount != null) const SizedBox(width: 8),
              badge,
            ],
          );

    final showIcons = label != null || showSurface || !compact;

    final content = Row(
      mainAxisSize:
          (showSurface || expandLabel) ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment:
          badgeBelow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (showIcons) ...[
          const Icon(Icons.account_balance_wallet_outlined,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 14, color: AppTheme.primary),
        ],
        if (label != null) ...[
          SizedBox(width: showIcons ? 8 : 0),
          if (expandLabel)
            Flexible(
              child: Text(
                label!,
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(label!, style: labelStyle),
          const SizedBox(width: 8),
        ] else if (showIcons)
          const SizedBox(width: 8),
        trailing,
      ],
    );

    if (!showSurface) return content;

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSM,
            vertical: AppTheme.spaceXS,
          ),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary),
      ),
      child: content,
    );
  }
}
