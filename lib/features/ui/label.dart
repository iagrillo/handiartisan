import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UILabel extends StatelessWidget {
  final String text;
  final bool required;
  final TextStyle? style;
  final String? errorText;

  const UILabel({
    required this.text,
    this.required = false,
    this.style,
    this.errorText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text + (required ? ' *' : ''),
          style: style ?? AppTheme.labelLarge,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: AppTheme.spaceSM),
            child: Text(errorText!, style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
          ),
      ],
    );
  }
}
