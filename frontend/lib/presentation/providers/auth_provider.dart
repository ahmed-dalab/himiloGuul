import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  String? _token;
  List<String> _menuItems = [];
  bool _isLoadingMenus = false;

  AuthProvider({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;
  List<String> get menuItems => _menuItems;
  bool get isLoadingMenus => _isLoadingMenus;

  // Login
  Future<bool> login(String email, String password) async {
    try {
      final data = await _authService.login(email, password);
      
      _token = data['token'];
      final userData = data['user'];
      
      // Parse Role
      // Parse Role
      UserRole role = UserRole.buyer;
      
      String? roleStr;
      if (userData['role'] is String) {
        roleStr = userData['role'];
      } else if (userData['roleId'] is Map) {
        // Fallback if role is nested in roleId object
        roleStr = userData['roleId']['name'];
      }
      
      if (roleStr != null) {
        final lowerRole = roleStr.toLowerCase();
        if (lowerRole == 'admin') {
          role = UserRole.admin;
        } else if (lowerRole == 'seller') {
          role = UserRole.seller;
        }
      }

      _currentUser = User(
        id: userData['_id'] ?? userData['id'],
        name: userData['name'],
        email: userData['email'],
        role: role,
      );

      // Load Menus if Admin or Seller
      if (role == UserRole.admin || role == UserRole.seller) {
        await _loadMenus();
      }

      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _menuItems = [];
    notifyListeners();
  }

  Future<void> _loadMenus() async {
    if (_token == null) return;
    
    _isLoadingMenus = true;
    notifyListeners();

    try {
      // Try fetching from backend
      final fetchedMenus = await _authService.fetchMenus(_token!);
      
      if (fetchedMenus.isNotEmpty) {
        _menuItems = fetchedMenus;
      } else {
        // Fallback logic
        _menuItems = _getFallbackMenus(_currentUser!.role);
      }
    } catch (e) {
      // Fallback on error
      _menuItems = _getFallbackMenus(_currentUser!.role);
    } finally {
      _isLoadingMenus = false;
      notifyListeners();
    }
  }
  
  List<String> _getFallbackMenus(UserRole role) {
    if (role == UserRole.admin) {
      return [
        'Home',
        'Business',
        'Deals',
        'Profile',
        'Settings', // Drawer start
        'Menus',
        'Permissions',
        'Roles',
      ];
    } else if (role == UserRole.seller) {
      return ['Dashboard', 'My Shops', 'Orders', 'Profile'];
    }
    return [];
  }
  
  // Helper to get bottom nav items (first 4)
  List<String> get bottomNavItems => _menuItems.take(4).toList();
  
  // Helper to get drawer items (after 4)
  List<String> get drawerItems => _menuItems.skip(4).toList();
}
