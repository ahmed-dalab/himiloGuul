import 'package:flutter/material.dart';

class AppMenu {
  final String id;
  final String name;
  final String path;
  final IconData icon;
  final String? parentId;
  final int order;

  AppMenu({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    this.parentId,
    this.order = 999,
  });

  factory AppMenu.fromJson(Map<String, dynamic> json) {
    final path = json['path'] ?? '';
    final name = json['name'] ?? '';
    final pathIcon = getIconForPath(path);
    // Use name as fallback when path has no specific icon (e.g. custom paths)
    final icon = pathIcon == Icons.circle ? getIconForName(name) : pathIcon;
    return AppMenu(
      id: json['_id'] ?? json['id'] ?? '',
      name: name,
      path: path,
      icon: icon,
      parentId: json['parentId']?.toString(),
      order: json['order'] ?? 999,
    );
  }

  /// Map path to Flutter icon for drawer and bottom navigation.
  static IconData getIconForPath(String path) {
    final p = path.toLowerCase().trim();
    switch (p) {
      case '/':
      case '/home':
        return Icons.home;
      case '/business':
        return Icons.business;
      case '/users':
        return Icons.people;
      case '/profile':
        return Icons.person;
      case '/admin/users':
        return Icons.people;
      case '/admin/roles':
        return Icons.admin_panel_settings;
      case '/admin/menus':
        return Icons.menu;
      case '/admin/permissions':
        return Icons.lock;
      case '/admin/settings':
        return Icons.settings;
      case '/admin/role-permissions':
        return Icons.link;
      case '/seller/dashboard':
        return Icons.home;
      case '/seller/my-businesses':
        return Icons.business;
      case '/seller/profile':
        return Icons.person;
      case '/seller/deals':
        return Icons.local_offer;
      case '/seller/contacts':
        return Icons.contacts;
      default:
        return Icons.circle;
    }
  }

  /// Map menu name to icon (fallback when path has no mapping).
  static IconData getIconForName(String name) {
    final n = name.toLowerCase().trim();
    switch (n) {
      case 'home':
        return Icons.home;
      case 'business':
        return Icons.business;
      case 'users':
        return Icons.people;
      case 'profile':
        return Icons.person;
      case 'roles':
        return Icons.admin_panel_settings;
      case 'menus':
        return Icons.menu;
      case 'permissions':
        return Icons.lock;
      case 'settings':
        return Icons.settings;
      case 'role permissions':
        return Icons.link;
      case 'deals':
        return Icons.local_offer;
      case 'contacts':
        return Icons.contacts;
      default:
        return Icons.circle;
    }
  }
}
