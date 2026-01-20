import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../routes/app_routes.dart';

class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final menuItems = authProvider.menuItems;
    
     if (_selectedIndex >= menuItems.length) {
       _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
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
              'Seller ${menuItems.isNotEmpty ? menuItems[_selectedIndex] : ""} Area',
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
        items: menuItems.map((item) {
           IconData icon;
          switch (item) {
            case 'Dashboard': icon = Icons.dashboard; break;
            case 'My Shops': icon = Icons.store; break;
            case 'Orders': icon = Icons.shopping_bag; break;
             case 'Profile': icon = Icons.person; break;
            default: icon = Icons.circle;
          }
          return BottomNavigationBarItem(
            icon: Icon(icon),
            label: item,
          );
        }).toList(),
      ),
    );
  }
}
