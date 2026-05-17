import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UIInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const UIInput({
    required this.controller,
    required this.hint,
    this.label,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spaceXS),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          obscureText: obscureText,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.textTertiary, size: 20)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
