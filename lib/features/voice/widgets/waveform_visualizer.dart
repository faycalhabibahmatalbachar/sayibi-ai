// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({
    super.key,
    required this.isActive,
    required this.color,
    required this.animController,
    this.barCount = 40,
  });

  final bool isActive;
  final Color color;
  final AnimationController animController;
  final int barCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: animController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, _buildBar),
          );
        },
      ),
    );
  }

  Widget _buildBar(int index) {
    final centerIndex = barCount / 2;
    final distanceFromCenter = (index - centerIndex).abs();
    final baseHeight = isActive ? 60 - (distanceFromCenter * 1.2) : 10.0;
    final animatedHeight = isActive
        ? baseHeight + (math.sin((index * 0.3) + (animController.value * math.pi * 2)) * 20)
        : baseHeight;
    final clampedHeight = animatedHeight.clamp(4.0, 60.0);

    return Container(
      width: 3,
      height: clampedHeight,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.7 + (animController.value * 0.3)),
        borderRadius: BorderRadius.circular(2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
