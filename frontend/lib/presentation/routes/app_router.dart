import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'app_routes.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/business/browse_business_screen.dart';
import '../screens/business/business_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/layouts/admin_layout.dart';
import '../screens/layouts/seller_layout.dart';
import '../screens/admin/users_screen.dart';
import '../screens/admin/roles_screen.dart';
import '../screens/admin/menus_screen.dart';
import '../screens/admin/permissions_screen.dart';
import '../screens/admin/role_permissions_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/admin_business_detail_screen.dart';
import '../screens/business/create_business_screen.dart';
import '../screens/business/contact_form_screen.dart';
import '../screens/business/contact_success_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.welcome,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) async {
        await authProvider.ensureRestored();
        final path = state.uri.path;
        final isAuth = authProvider.isAuthenticated;
        final user = authProvider.currentUser;

        // Logged in: redirect away from auth/welcome to role-based layout
        if (isAuth && user != null) {
          if (path == AppRoutes.welcome ||
              path == AppRoutes.login ||
              path == AppRoutes.register) {
            if (user.role == UserRole.admin) return '/admin';
            if (user.role == UserRole.seller) return '/seller';
            return AppRoutes.browseBusiness;
          }
        }

        // Not logged in: redirect away from protected layouts and create-business
        if (!isAuth &&
            (path.startsWith('/admin') ||
                path.startsWith('/seller') ||
                path == AppRoutes.createBusiness)) {
          return AppRoutes.welcome;
        }

        return null;
      },
      routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.browseBusiness, // Buyer essentially
        builder: (context, state) => const BrowseBusinessScreen(),
      ),
      GoRoute(
        path: AppRoutes.createBusiness,
        builder: (context, state) => const CreateBusinessScreen(),
      ),
      GoRoute(
        path: AppRoutes.users,
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminLayout(),
      ),
      GoRoute(
        path: '/seller',
        builder: (context, state) => const SellerLayout(),
      ),
      // Admin management routes
      GoRoute(
        path: AppRoutes.rolesManagement,
        builder: (context, state) => const RolesScreen(),
      ),
      GoRoute(
        path: AppRoutes.menusManagement,
        builder: (context, state) => const MenusScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissionsManagement,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.rolePermissionsManagement,
        builder: (context, state) => const RolePermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin/business/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminBusinessDetailScreen(businessId: id);
        },
      ),
      // Public business detail + contact flow
      GoRoute(
        path: '${AppRoutes.businessDetail}/:id',
        routes: [
          GoRoute(
            path: 'contact',
            builder: (context, state) {
              final businessId = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ContactFormScreen(
                businessId: businessId,
                businessName: extra?['businessName'] as String? ?? 'Business',
                businessCategory: extra?['businessCategory'] as String? ?? '',
                imageUrl: extra?['imageUrl'] as String?,
                sellerRef: extra?['sellerRef'] as String? ?? '',
              );
            },
          ),
          GoRoute(
            path: 'contact/success',
            builder: (context, state) {
              final businessId = state.pathParameters['id']!;
              return ContactSuccessScreen(businessId: businessId);
            },
          ),
        ],
        builder: (context, state) {
          final businessId = state.pathParameters['id']!;
          return BusinessDetailScreen(businessId: businessId);
        },
      ),
    ],
    );
  }
}
