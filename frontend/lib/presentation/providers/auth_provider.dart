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

  /// Exactly these 4 menu names (case-insensitive) go to bottom navigation. All others go to drawer.
  /// No menu is shown in both.
  static const List<String> _bottomNavMenuNames = ['home', 'business', 'users', 'profile'];

  AuthProvider({AuthService? authService}) 
      : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;
  List<AppMenu> get allMenus => _allMenus;
  bool get isLoadingMenus => _isLoadingMenus;

  /// Reload menus from the backend (e.g. after creating/editing/deleting menus on admin portal).
  /// Call this so the drawer/sidebar updates after changes.
  Future<void> refreshMenus() async {
    if (_currentUser == null || _token == null) return;
    await _loadMenus();
  }

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
            
        // Sort by order
        _allMenus.sort((a, b) => a.order.compareTo(b.order));
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
  
  /// Fallback when backend fails: empty so menu visibility stays permission-based (no hard-coded menus).
  List<AppMenu> _getFallbackMenus(UserRole role) {
    return [];
  }
  
  /// Bottom nav: only the 4 menus named Home, Business, Users, Profile (first match per name, in that order).
  /// No menu appears in both bottom nav and drawer.
  List<AppMenu> get bottomNavItems {
    final result = <AppMenu>[];
    for (final name in _bottomNavMenuNames) {
      final match = _allMenus.where(
        (m) => m.name.toLowerCase().trim() == name,
      );
      if (match.isNotEmpty) {
        result.add(match.first);
      }
    }
    return result;
  }

  /// Drawer: all menus that are NOT one of the 4 bottom nav menus (by name).
  List<AppMenu> get drawerItems {
    return _allMenus
        .where((m) => !_bottomNavMenuNames.contains(m.name.toLowerCase().trim()))
        .toList();
  }

  /// Menus for admin portal only (path starts with /admin). Use for permission-driven display.
  List<AppMenu> get adminMenus {
    return _allMenus.where((m) => m.path.startsWith('/admin')).toList();
  }

  /// Menus for seller portal only (path starts with /seller). Use for permission-driven display.
  List<AppMenu> get sellerMenus {
    return _allMenus.where((m) => m.path.startsWith('/seller')).toList();
  }
}
