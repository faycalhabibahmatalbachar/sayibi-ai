import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await ref.read(authProvider.notifier).waitUntilSessionReady();
      if (!mounted) return;

      final redirect = await ref.read(authProvider.notifier).tryCompleteSupabaseEmailRedirect();
      if (!mounted) return;
      if (redirect == true) {
        context.go('/main');
        return;
      }
      if (redirect == false) {
        context.go('/login');
        return;
      }

      if (ref.read(authProvider).authenticated) {
        context.go('/main');
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      final done = p.getBool('onboarding_done') ?? false;
      if (!mounted) return;
      context.go(done ? '/login' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/lottie/splash.json',
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.auto_awesome, size: 72),
              ),
            ).animate().fade().scale(),
            const SizedBox(height: 16),
            Text(AppStrings.appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(AppStrings.tagline),
          ],
        ),
      ),
    );
  }
}
