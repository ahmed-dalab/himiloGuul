import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/menu_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/auth_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AuthStorageService _storage = AuthStorageService();
  User? _currentUser;
  String? _token;
  List<AppMenu> _allMenus = [];
  bool _isLoadingMenus = false;
  Future<void>? _restoreFuture;

  // Bottom navigation menus (only these 4 paths)
  static const List<String> _bottomNavPaths = ['/', '/business', '/deals', '/profile'];

  AuthProvider({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;
  List<AppMenu> get allMenus => _allMenus;
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

      // Persist auth for session restore
      await _storage.saveToken(_token!);
      await _storage.saveUser({
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'role': role.name,
      });

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
    _allMenus = [];
    _storage.clear();
    notifyListeners();
  }

  /// Restore session from storage. Call once at app start; safe to await multiple times.
  Future<void> ensureRestored() async {
    _restoreFuture ??= _doRestore();
    await _restoreFuture;
  }

  Future<void> _doRestore() async {
    try {
      final token = await _storage.getToken();
      final userMap = await _storage.getUser();
      if (token == null || userMap == null) return;

      _token = token;
      final roleStr = (userMap['role'] as String?)?.toLowerCase();
      UserRole role = UserRole.buyer;
      if (roleStr == 'admin') {
        role = UserRole.admin;
      } else if (roleStr == 'seller') {
        role = UserRole.seller;
      }

      _currentUser = User(
        id: userMap['id'] as String? ?? '',
        name: userMap['name'] as String? ?? '',
        email: userMap['email'] as String? ?? '',
        role: role,
      );

      if (role == UserRole.admin || role == UserRole.seller) {
        await _loadMenus();
      }
      notifyListeners();
    } catch (_) {
      await _storage.clear();
    }
  }

  Future<void> _loadMenus() async {
    if (_token == null) return;
    
    _isLoadingMenus = true;
    notifyListeners();

    try {
      // Try fetching from backend
      final fetchedMenus = await _authService.fetchMenus(token: _token!);
      
      if (fetchedMenus.isNotEmpty) {
        // Convert to AppMenu objects
        _allMenus = fetchedMenus
            .map((menu) => AppMenu.fromJson(menu))
            .toList();
      } else {
        // Fallback logic - create menus from fallback list
        _allMenus = _getFallbackMenus(_currentUser!.role);
      }
    } catch (e) {
      // Fallback on error
      _allMenus = _getFallbackMenus(_currentUser!.role);
    } finally {
      _isLoadingMenus = false;
      notifyListeners();
    }
  }
  
  List<AppMenu> _getFallbackMenus(UserRole role) {
    if (role == UserRole.admin) {
      return [
        AppMenu(id: '1', name: 'Home', path: '/', icon: Icons.home),
        AppMenu(id: '2', name: 'Business', path: '/business', icon: Icons.business),
        AppMenu(id: '3', name: 'Deals', path: '/deals', icon: Icons.local_offer),
        AppMenu(id: '4', name: 'Profile', path: '/profile', icon: Icons.person),
        AppMenu(id: '5', name: 'Users', path: '/admin/users', icon: Icons.people),
        AppMenu(id: '6', name: 'Roles', path: '/admin/roles', icon: Icons.admin_panel_settings),
        AppMenu(id: '7', name: 'Menus', path: '/admin/menus', icon: Icons.menu),
        AppMenu(id: '8', name: 'Permissions', path: '/admin/permissions', icon: Icons.lock),
        AppMenu(id: '9', name: 'Settings', path: '/admin/settings', icon: Icons.settings),
      ];
    } else if (role == UserRole.seller) {
      return [
        AppMenu(id: '1', name: 'Home', path: '/', icon: Icons.home),
        AppMenu(id: '2', name: 'Business', path: '/business', icon: Icons.business),
        AppMenu(id: '3', name: 'Deals', path: '/deals', icon: Icons.local_offer),
        AppMenu(id: '4', name: 'Profile', path: '/profile', icon: Icons.person),
      ];
    }
    return [];
  }
  
  // Get bottom navigation items (only Home, Business, Deals, Profile)
  List<AppMenu> get bottomNavItems {
    return _allMenus
        .where((menu) => _bottomNavPaths.contains(menu.path))
        .toList();
  }
  
  // Get drawer items (all other menus)
  List<AppMenu> get drawerItems {
    return _allMenus
        .where((menu) => !_bottomNavPaths.contains(menu.path))
        .toList();
  }
}
