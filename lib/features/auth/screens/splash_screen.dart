import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
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
            const Icon(Icons.auto_awesome, size: 72).animate().fade().scale(),
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
