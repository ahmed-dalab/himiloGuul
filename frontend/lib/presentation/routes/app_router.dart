import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/business/browse_business_screen.dart';
import '../screens/business/business_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.browseBusiness,
        builder: (context, state) => const BrowseBusinessScreen(),
      ),
      // Add other routes here as they are implemented
      GoRoute(
        path: '${AppRoutes.businessDetail}/:id',
        builder: (context, state) {
           final businessId = state.pathParameters['id']!;
           return BusinessDetailScreen(businessId: businessId);
        },
      ),
    ],
  );
}
