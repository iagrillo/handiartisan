import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class CustomBottomAppBar extends StatelessWidget {
  const CustomBottomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: AppTheme.surface,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.people),
              color: AppTheme.primary,
              tooltip: 'Artisan',
              onPressed: () {
                Navigator.of(context).pushNamed('/directory');
              },
            ),
            IconButton(
              icon: const Icon(Icons.store),
              color: AppTheme.textTertiary,
              tooltip: 'Store',
              onPressed: () {
                Navigator.of(context).pushNamed('/stores');
              },
            ),
            IconButton(
              icon: const Icon(Icons.build),
              color: AppTheme.textTertiary,
              tooltip: 'Equipment',
              onPressed: () {
                Navigator.of(context).pushNamed('/equipment');
              },
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              color: AppTheme.textTertiary,
              tooltip: 'Wallet',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              color: AppTheme.textTertiary,
              tooltip: 'Edit Profile',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
