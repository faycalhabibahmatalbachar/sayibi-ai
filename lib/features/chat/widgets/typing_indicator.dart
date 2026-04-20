import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';

/// Indicateur « IA en train d’écrire » — Lottie si disponible, sinon points animés.
class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 40,
            child: Lottie.asset(
              'assets/lottie/typing.json',
              repeat: true,
              errorBuilder: (_, __, ___) => Row(
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.darkTextSecondary,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).fade(duration: 400.ms, delay: (i * 120).ms);
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ChadGpt…',
            style: TextStyle(
              color: AppColors.darkTextTertiary.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compatibilité avec l’ancien nom.
typedef TypingIndicator = TypingIndicatorWidget;
