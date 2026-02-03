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
    return AppMenu(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      icon: getIconForPath(json['path'] ?? ''),
      parentId: json['parentId']?.toString(),
      order: json['order'] ?? 999,
    );
  }

  // Map paths to Flutter icons (public for use in menus screen)
  static IconData getIconForPath(String path) {
    switch (path.toLowerCase()) {
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
      default:
        return Icons.circle;
    }
  }
}
