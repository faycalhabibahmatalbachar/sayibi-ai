import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  const WaveformWidget({super.key, this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (i) {
        final h = active ? 12.0 + (i % 4) * 8.0 : 10.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 4,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.9 : 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
