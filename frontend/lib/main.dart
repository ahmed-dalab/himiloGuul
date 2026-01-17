import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/business_provider.dart';
import 'presentation/routes/app_router.dart';
import 'config/app_theme.dart';

void main() {
  runApp(const HimiloGuulApp());
}

class HimiloGuulApp extends StatelessWidget {
  const HimiloGuulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
      ],
      child: MaterialApp.router(
        title: 'HimiloGuul',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
