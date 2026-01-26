import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/menu_model.dart';
import '../../routes/app_routes.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
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

  // Navigate to screen based on menu path
  void _navigateToScreen(BuildContext context, String path) {
    switch (path) {
      case '/admin/users':
        context.go(AppRoutes.userManagement);
        break;
      case '/admin/roles':
        context.go(AppRoutes.rolesManagement);
        break;
      case '/admin/menus':
        context.go(AppRoutes.menusManagement);
        break;
      case '/admin/permissions':
        context.go(AppRoutes.permissionsManagement);
        break;
      case '/admin/settings':
        context.go(AppRoutes.settings);
        break;
      default:
        // If path doesn't match, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation to $path not implemented yet')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // items from provider
    final bottomNavItems = authProvider.bottomNavItems;
    final drawerItems = authProvider.drawerItems;
    
    // Safety check for index
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(authProvider.currentUser?.name ?? 'Admin'),
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
              onTap: () {
                // Close drawer
                Navigator.pop(context);
                // Navigate to the corresponding screen based on menu path
                _navigateToScreen(context, menu.path);
              },
            )),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Admin ${_getOrderedBottomNavItems(bottomNavItems).isNotEmpty ? _getOrderedBottomNavItems(bottomNavItems)[_selectedIndex].name : ""} Area',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 8),
            const Text('Manage your application here.'),
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
