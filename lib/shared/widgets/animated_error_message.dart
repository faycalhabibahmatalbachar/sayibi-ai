import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

class AnimatedErrorMessage extends StatelessWidget {
  const AnimatedErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.showLottie = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool showLottie;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLottie)
            Lottie.asset(
              'assets/lottie/error.json',
              width: 120,
              height: 120,
              repeat: false,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.error_outline_rounded,
                color: AppColors.errorLight,
                size: 72,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.errorLight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(AppStrings.retry),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }
}
