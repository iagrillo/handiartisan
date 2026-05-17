import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UITextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? label;
  final String? errorText;

  const UITextArea({
    required this.controller,
    required this.hint,
    this.minLines = 3,
    this.maxLines = 8,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.errorText,
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
          minLines: minLines,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
