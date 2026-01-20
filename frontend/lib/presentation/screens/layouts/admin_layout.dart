import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../config/app_colors.dart';
import '../../routes/app_routes.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

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
        title: Text('Admin Panel - ${bottomNavItems.isNotEmpty ? bottomNavItems[_selectedIndex] : "Home"}'),
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
            ...drawerItems.map((item) => ListTile(
              leading: const Icon(Icons.circle_outlined), 
              title: Text(item),
              onTap: () {
                // Handle drawer navigation
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigating to $item')),
                );
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
              'Admin ${bottomNavItems.isNotEmpty ? bottomNavItems[_selectedIndex] : ""} Area',
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
        items: bottomNavItems.asMap().entries.map((entry) {
          IconData icon;
          // Dynamically map icons or use a helper
          switch (entry.value) {
            case 'Home': icon = Icons.home; break;
            case 'Business': icon = Icons.business; break;
            case 'Deals': icon = Icons.local_offer; break;
            case 'Profile': icon = Icons.person; break;
            case 'Dashboard': icon = Icons.dashboard; break;
            case 'Users': icon = Icons.people; break;
            case 'Businesses': icon = Icons.store; break;
            case 'Settings': icon = Icons.settings; break;
            default: icon = Icons.circle;
          }
          return BottomNavigationBarItem(
            icon: Icon(icon),
            label: entry.value,
          );
        }).toList(),
      ),
    );
  }
}
