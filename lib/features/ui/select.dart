import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class UISelect extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;

  const UISelect({
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
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
        DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          style: AppTheme.bodyMedium,
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
