import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UIButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool disabled;
  final ButtonStyle? style;
  final IconData? icon;
  final bool outlined;

  const UIButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.disabled = false,
    this.style,
    this.icon,
    this.outlined = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.surface,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppTheme.spaceSM),
                  Text(label),
                ],
              )
            : Text(label);

    if (outlined) {
      return OutlinedButton(
        onPressed: (disabled || loading) ? null : onPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: (disabled || loading) ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
