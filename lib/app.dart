import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'main_shell.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (ctx, state) => '/splash'),
    GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
    GoRoute(path: '/main', builder: (ctx, state) => const MainShell()),
  ],
);

class SayibiApp extends StatelessWidget {
  const SayibiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SAYIBI AI',
      theme: AppTheme.dark(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
