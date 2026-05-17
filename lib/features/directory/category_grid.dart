import 'package:flutter/material.dart';

import '../models/category.dart';
import '../ui/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final void Function(Category)? onCategoryTap;

  const CategoryGrid({required this.categories, this.onCategoryTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, idx) {
        final cat = categories[idx];
        return GestureDetector(
          onTap: onCategoryTap != null ? () => onCategoryTap!(cat) : null,
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category, size: 32, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: AppTheme.titleSmall
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
