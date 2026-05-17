import 'package:flutter/material.dart';
import '../features/ui/app_theme.dart';
import '../features/directory/store_filter_page.dart';

class MainBottomNav extends StatefulWidget {
  final int currentIndex;

  const MainBottomNav({Key? key, required this.currentIndex}) : super(key: key);

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  void _onTap(int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, '/directory', (route) => false);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreFilterPage()),
        );
        break;
      case 2:
        Navigator.pushNamed(context, '/equipment');
        break;
      case 3:
        Navigator.pushNamed(context, '/services');
        break;
      case 4:
        Navigator.pushNamed(context, '/wallet');
        break;
      case 5:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textTertiary,
          backgroundColor: AppTheme.surface,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outlined), label: 'Directory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined), label: 'Store'),
            BottomNavigationBarItem(
                icon: Icon(Icons.build_outlined), label: 'Equipment'),
            BottomNavigationBarItem(
                icon: Icon(Icons.handyman_outlined), label: 'Services'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Wallet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_outlined), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
