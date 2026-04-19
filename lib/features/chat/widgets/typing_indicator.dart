import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).fade(duration: 400.ms, delay: (i * 120).ms);
        }),
      ),
    );
  }
}
