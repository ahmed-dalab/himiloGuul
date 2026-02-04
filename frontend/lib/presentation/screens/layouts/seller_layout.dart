import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/menu_model.dart';
import '../../routes/app_routes.dart';
import '../seller/seller_dashboard_screen.dart';
import '../seller/seller_my_businesses_screen.dart';
import '../seller/seller_profile_screen.dart';
import '../seller/seller_contacts_screen.dart';

class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _selectedIndex = 0;
  String _currentPath = '/seller/dashboard';

  // Seller portal: Home, My Business, Contacts, Profile (permission-driven)
  static const List<String> _bottomNavOrder = ['home', 'my business', 'contacts', 'profile'];

  List<AppMenu> _getOrderedBottomNavItems(List<AppMenu> items) {
    final ordered = <AppMenu>[];
    for (final name in _bottomNavOrder) {
      final match = items.where((m) => m.name.toLowerCase().trim() == name);
      if (match.isNotEmpty) ordered.add(match.first);
    }
    return ordered;
  }

  List<AppMenu> _getEffectiveBottomNavItems(List<AppMenu> items) {
    return _getOrderedBottomNavItems(items);
  }

  Widget _bodyForPath(String path) {
    switch (path) {
      case '/seller/dashboard':
        return const SellerDashboardScreen();
      case '/seller/my-businesses':
        return const SellerMyBusinessesScreen();
      case '/seller/profile':
        return const SellerProfileScreen();
      case '/seller/contacts':
        return const SellerContactsScreen();
      default:
        return const SellerDashboardScreen();
    }
  }

  void _navigateToScreen(BuildContext context, String path) {
    setState(() {
      _currentPath = path;
      final sellerMenus = context.read<AuthProvider>().sellerMenus;
      final effectiveItems = _getEffectiveBottomNavItems(_getOrderedBottomNavItems(sellerMenus));
      final idx = effectiveItems.indexWhere((m) => m.path == path);
      _selectedIndex = idx >= 0 ? idx : _selectedIndex;
    });
    Navigator.pop(context); // close drawer
  }

  static const List<String> _sellerDrawerExclude = ['home', 'my business', 'contacts', 'profile'];

  static Future<void> _showLogoutConfirm(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      authProvider.logout();
      context.go(AppRoutes.welcome);
    }
  }

  List<AppMenu> _getSellerDrawerItems(List<AppMenu> sellerMenus) {
    return sellerMenus
        .where((m) => !_sellerDrawerExclude.contains(m.name.toLowerCase().trim()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // Permission-driven: only seller-path menus (menus without permission are hidden)
    final sellerMenus = authProvider.sellerMenus;
    final effectiveItems = _getEffectiveBottomNavItems(_getOrderedBottomNavItems(sellerMenus));
    final drawerItems = _getSellerDrawerItems(sellerMenus);

    if (_selectedIndex >= effectiveItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HimiloGuul',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirm(context, authProvider),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(authProvider.currentUser?.name ?? 'Seller'),
              accountEmail: Text(authProvider.currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primaryBlue),
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
              ),
            ),
            ...drawerItems.map((menu) => ListTile(
                  leading: Icon(menu.icon),
                  title: Text(menu.name),
                  onTap: () => _navigateToScreen(context, menu.path),
                )),
          ],
        ),
      ),
      body: _bodyForPath(_currentPath),
      bottomNavigationBar: effectiveItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, effectiveItems.length - 1),
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _currentPath = effectiveItems[index].path;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: Colors.grey,
              items: effectiveItems.map((menu) {
                return BottomNavigationBarItem(
                  icon: Icon(menu.icon, color: Colors.grey),
                  activeIcon: Icon(menu.icon, color: AppColors.primaryBlue),
                  label: menu.name,
                );
              }).toList(),
            )
          : null,
    );
  }
}
