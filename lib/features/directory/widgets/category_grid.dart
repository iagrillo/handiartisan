import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  final List<String> categories;
  const CategoryGrid({required this.categories, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppTheme.spaceSM,
      crossAxisSpacing: AppTheme.spaceSM,
      childAspectRatio: 3,
      children: categories
          .map(
            (cat) => Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Center(
                child: Text(cat, style: AppTheme.labelLarge),
              ),
            ),
          )
          .toList(),
    );
  }
}
