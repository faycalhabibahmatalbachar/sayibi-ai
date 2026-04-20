// ignore_for_file: deprecated_member_use

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../screens/voice_call_screen.dart';

class AIVoiceBubble extends StatelessWidget {
  const AIVoiceBubble({
    super.key,
    required this.state,
    required this.isSpeaking,
    required this.animController,
    required this.glowController,
  });

  final VoiceCallState state;
  final bool isSpeaking;
  final AnimationController animController;
  final AnimationController glowController;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bulle vocale SAYIBI',
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSpeaking) ...[
            _buildGlowCircle(size: 280, opacity: 0.08, animation: glowController),
            _buildGlowCircle(
              size: 240,
              opacity: 0.12,
              animation: glowController,
              delay: 300.ms,
            ),
            _buildGlowCircle(
              size: 200,
              opacity: 0.16,
              animation: glowController,
              delay: 600.ms,
            ),
          ],
          AvatarGlow(
            glowColor: _getBubbleColor(),
            glowRadiusFactor: isSpeaking ? 0.6 : 0.3,
            duration: const Duration(milliseconds: 2000),
            repeat: isSpeaking,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: isSpeaking ? 180 : 160,
              height: isSpeaking ? 180 : 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getBubbleColor().withOpacity(0.82),
                    _getBubbleColor().withOpacity(0.42),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getBubbleColor().withOpacity(0.5),
                    blurRadius: isSpeaking ? 60 : 40,
                    spreadRadius: isSpeaking ? 10 : 5,
                  ),
                ],
              ),
              child: Center(child: _buildBubbleContent()),
            ),
          ),
          if (isSpeaking)
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  final delay = index * 0.3;
                  final scale = 1.0 +
                      (animController.value > delay
                          ? (animController.value - delay) * 0.5
                          : 0.0);
                  final opacity = 1.0 -
                      (animController.value > delay
                          ? (animController.value - delay)
                          : 0.0);

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getBubbleColor().withOpacity(opacity * 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildGlowCircle({
    required double size,
    required double opacity,
    required AnimationController animation,
    Duration delay = Duration.zero,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getBubbleColor().withOpacity(opacity * animation.value),
          ),
        );
      },
    ).animate(delay: delay).fadeIn(duration: 800.ms).scale(duration: 800.ms);
  }

  Widget _buildBubbleContent() {
    switch (state) {
      case VoiceCallState.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 48)
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(0.9, 0.9),
                  duration: 1000.ms,
                ),
            const SizedBox(height: 12),
            const Text(
              'Je vous ecoute...',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      case VoiceCallState.processing:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Analyse en cours...',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      case VoiceCallState.speaking:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 3000.ms),
            const SizedBox(height: 12),
            const Text(
              'Je reponds...',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      case VoiceCallState.error:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
            SizedBox(height: 12),
            Text(
              'Erreur',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SAYIBI AI',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
    }
  }

  Color _getBubbleColor() {
    switch (state) {
      case VoiceCallState.listening:
        return AppColors.info;
      case VoiceCallState.processing:
        return AppColors.primary;
      case VoiceCallState.speaking:
        return AppColors.success;
      case VoiceCallState.error:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
