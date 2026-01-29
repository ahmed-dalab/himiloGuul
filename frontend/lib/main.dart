import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/business_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/routes/app_router.dart';
import 'config/app_theme.dart';

void main() {
  final authProvider = AuthProvider();
  runApp(HimiloGuulApp(authProvider: authProvider));
}

class HimiloGuulApp extends StatelessWidget {
  final AuthProvider? authProvider;

  const HimiloGuulApp({super.key, this.authProvider});

  /// Ensures we always have an AuthProvider (fixes hot reload / null on rebuild).
  AuthProvider get _auth => authProvider ?? _defaultAuthProvider;
  static final AuthProvider _defaultAuthProvider = AuthProvider();

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp.router(
        title: 'HimiloGuul',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.createRouter(auth),
      ),
    );
  }
}
