class ApiConstants {
  // Base URL
  // Use 10.0.2.2 for Android Emulator to access localhost of the host machine
  // Use localhost for iOS Simulator or Web
  static const String baseUrl = 'http://10.0.2.2:3000/api'; 
  
  // Auth endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  
  // User endpoints
  static const String users = '/users';
  static const String userProfile = '$users/profile';
  
  // Business endpoints
  static const String businesses = '/business';
  static const String myBusinesses = '$businesses/my';
  
  // Admin endpoints
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String adminActivities = '$admin/activities';
  static const String adminBusinesses = '$admin/businesses';
  static const String adminPendingBusinesses = '$adminBusinesses/pending';
  static const String adminUsers = '$admin/users';
  static const String adminContacts = '$admin/contacts';
  
  // Role endpoints
  static const String roles = '/roles';
  
  // Permission endpoints
  static const String permissions = '/permissions';
  
  // Role-Permission endpoints
  static const String rolePermissions = '/role-permissions';
  
  // Menu endpoints
  static const String menus = '/menus';
  static const String menusMe = '/menus/me';
  
  // Contact endpoints
  static const String contacts = '/contacts';

  // Settings endpoints
  static const String settings = '/settings';
}
