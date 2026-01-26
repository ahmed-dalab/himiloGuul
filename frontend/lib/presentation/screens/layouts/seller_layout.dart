import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/menu_model.dart';
import '../../routes/app_routes.dart';

class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _selectedIndex = 0;

  // Order bottom nav items: Home, Business, Deals, Profile
  List<AppMenu> _getOrderedBottomNavItems(List<AppMenu> items) {
    const order = ['/', '/business', '/deals', '/profile'];
    final ordered = <AppMenu>[];
    for (final path in order) {
      try {
        final menu = items.firstWhere((item) => item.path == path);
        ordered.add(menu);
      } catch (e) {
        // Menu not found, skip it
        continue;
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomNavItems = authProvider.bottomNavItems;
    
     if (_selectedIndex >= bottomNavItems.length) {
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
            onPressed: () {
              authProvider.logout();
              context.go(AppRoutes.welcome);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Seller ${_getOrderedBottomNavItems(bottomNavItems).isNotEmpty ? _getOrderedBottomNavItems(bottomNavItems)[_selectedIndex].name : ""} Area',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            const Text('Manage your shops and orders.'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: _getOrderedBottomNavItems(bottomNavItems).map((menu) {
          return BottomNavigationBarItem(
            icon: Icon(menu.icon, color: Colors.grey),
            activeIcon: Icon(menu.icon, color: AppColors.primaryBlue),
            label: menu.name,
          );
        }).toList(),
      ),
    );
  }
}
