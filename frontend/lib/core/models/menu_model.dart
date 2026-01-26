import 'package:flutter/material.dart';

class AppMenu {
  final String id;
  final String name;
  final String path;
  final IconData icon;
  final String? parentId;

  AppMenu({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    this.parentId,
  });

  factory AppMenu.fromJson(Map<String, dynamic> json) {
    return AppMenu(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      icon: _getIconForPath(json['path'] ?? ''),
      parentId: json['parentId']?.toString(),
    );
  }

  // Map paths to Flutter icons
  static IconData _getIconForPath(String path) {
    switch (path.toLowerCase()) {
      case '/':
      case '/home':
        return Icons.home;
      case '/business':
        return Icons.business;
      case '/deals':
        return Icons.local_offer;
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
      default:
        return Icons.circle;
    }
  }

  // Map menu name to icon (fallback)
  static IconData getIconForName(String name) {
    switch (name.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'business':
        return Icons.business;
      case 'deals':
        return Icons.local_offer;
      case 'profile':
        return Icons.person;
      case 'users':
        return Icons.people;
      case 'roles':
        return Icons.admin_panel_settings;
      case 'menus':
        return Icons.menu;
      case 'permissions':
        return Icons.lock;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.circle;
    }
  }
}
