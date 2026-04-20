import 'dart:math' as math;

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bulle « personnage » ChadGpt : sphère vitrée, reflets, yeux et sourire discrets.
class AiLoginMascot extends StatefulWidget {
  const AiLoginMascot({super.key, this.size = 132});

  final double size;

  @override
  State<AiLoginMascot> createState() => _AiLoginMascotState();
}

class _AiLoginMascotState extends State<AiLoginMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_breath.value);
        final scale = 1.0 + 0.03 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: AvatarGlow(
        glowRadiusFactor: 0.55,
        glowColor: AppColors.primaryLight,
        duration: const Duration(milliseconds: 2400),
        repeat: true,
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      AppColors.primaryLight.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: Size(d, d),
                painter: _BubbleFacePainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final glossCenter = Offset(c.dx - r * 0.15, c.dy - r * 0.2);
    final gloss = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.55),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glossCenter, radius: r * 0.5));
    canvas.drawCircle(glossCenter, r * 0.38, gloss);

    final eye = Paint()
      ..color = AppColors.darkBackground.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    final eyeY = c.dy - r * 0.06;
    final eyeDx = r * 0.22;
    canvas.drawCircle(Offset(c.dx - eyeDx, eyeY), r * 0.07, eye);
    canvas.drawCircle(Offset(c.dx + eyeDx, eyeY), r * 0.07, eye);

    final shine = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(c.dx - eyeDx - r * 0.02, eyeY - r * 0.02), r * 0.022, shine);
    canvas.drawCircle(Offset(c.dx + eyeDx - r * 0.02, eyeY - r * 0.02), r * 0.022, shine);

    final smile = Paint()
      ..color = AppColors.darkBackground.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;

    final smileRect = Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.18),
      width: r * 0.72,
      height: r * 0.38,
    );
    canvas.drawArc(smileRect, math.pi * 0.12, math.pi * 0.76, false, smile);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
