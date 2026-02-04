import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/menu_model.dart';
import '../../routes/app_routes.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_business_screen.dart';
import '../admin/users_screen.dart';
import '../admin/admin_profile_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  // Order bottom nav items by name: Home, Business, Users, Profile (matches AuthProvider filter)
  static const List<String> _bottomNavOrder = ['home', 'business', 'users', 'profile'];

  List<AppMenu> _getOrderedBottomNavItems(List<AppMenu> items) {
    final ordered = <AppMenu>[];
    for (final name in _bottomNavOrder) {
      final match = items.where((m) => m.name.toLowerCase().trim() == name);
      if (match.isNotEmpty) ordered.add(match.first);
    }
    return ordered;
  }

  // Permission-driven: no fallback menus. Bottom nav only when we have 2+ items.
  List<AppMenu> _getEffectiveBottomNavItems(List<AppMenu> items) {
    return _getOrderedBottomNavItems(items);
  }

  // Navigate to screen based on menu path (permission-driven; only admin menus shown)
  void _navigateToScreen(BuildContext context, String path) {
    if (path == '/admin' || path == '/admin/') {
      setState(() => _selectedIndex = 0);
      return;
    }
    if (path == '/admin/business') {
      setState(() => _selectedIndex = 1);
      return;
    }
    if (path == '/admin/users') {
      setState(() => _selectedIndex = 2);
      return;
    }
    if (path == '/admin/profile') {
      setState(() => _selectedIndex = 3);
      return;
    }
    switch (path) {
      case '/admin/roles':
        context.go(AppRoutes.rolesManagement);
        break;
      case '/admin/menus':
        context.go(AppRoutes.menusManagement);
        break;
      case '/admin/permissions':
        context.go(AppRoutes.permissionsManagement);
        break;
      case '/admin/role-permissions':
        context.go(AppRoutes.rolePermissionsManagement);
        break;
      case '/admin/settings':
        context.go(AppRoutes.settings);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation to $path not implemented yet')),
        );
    }
  }

  static const List<String> _adminBottomNavNames = ['home', 'business', 'users', 'profile'];

  List<AppMenu> _getAdminDrawerItems(List<AppMenu> adminMenus) {
    return adminMenus
        .where((m) => !_adminBottomNavNames.contains(m.name.toLowerCase().trim()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Permission-driven: only admin-path menus (menus without permission are hidden)
    final adminMenus = authProvider.adminMenus;
    final effectiveBottomItems = _getEffectiveBottomNavItems(_getOrderedBottomNavItems(adminMenus));
    final drawerItems = _getAdminDrawerItems(adminMenus);

    // Safety check for index
    if (_selectedIndex >= effectiveBottomItems.length) {
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
      body: _selectedIndex == 0
          ? const AdminDashboardScreen()
          : _selectedIndex == 1
              ? const AdminBusinessScreen()
              : _selectedIndex == 2
                  ? const UsersScreen()
                  : const AdminProfileScreen(),
      bottomNavigationBar: effectiveBottomItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, effectiveBottomItems.length - 1),
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: Colors.grey,
              items: effectiveBottomItems.map((menu) {
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
