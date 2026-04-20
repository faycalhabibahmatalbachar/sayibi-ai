import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

import '../../../core/theme/app_colors.dart';

/// Fond animé commun aux écrans Login / Register.
class AuthMeshBackground extends StatelessWidget {
  const AuthMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedMeshGradient(
      colors: const [
        Color(0xFF0A0E27),
        Color(0xFF2D1B69),
        AppColors.primary,
        AppColors.accentDark,
      ],
      options: AnimatedMeshGradientOptions(
        frequency: 4,
        amplitude: 28,
        speed: 1.15,
        grain: 0.07,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
