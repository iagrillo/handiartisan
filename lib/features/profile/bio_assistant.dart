import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class BioAssistant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          children: [
            const Text('AI Bio Assistant', style: AppTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
