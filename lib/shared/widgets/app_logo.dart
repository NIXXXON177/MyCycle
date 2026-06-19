import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mycycle/core/constants/app_colors.dart';

/// Логотип MyCycle — цикл с маркером дня.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 120,
    this.animate = false,
    this.animation,
  });

  final double size;
  final bool animate;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    if (animate && animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) => _LogoFrame(
          size: size,
          progress: animation!.value,
        ),
      );
    }
    return _LogoFrame(size: size, progress: 1);
  }
}

class _LogoFrame extends StatelessWidget {
  const _LogoFrame({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppLogoPainter(progress: progress),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  _AppLogoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final breathe = 0.96 + 0.04 * math.sin(progress * math.pi * 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathe);

    final shadow = Paint()
      ..color = AppColors.pinkDark.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(const Offset(0, 6), radius * 0.92, shadow);

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.pink, AppColors.purple],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, bg);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.95),
        ],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius * 0.72));

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.72),
      -math.pi / 2,
      math.pi * 1.65,
      false,
      ringPaint,
    );

    final dotAngle = -math.pi / 2 + progress * math.pi * 2;
    final dotCenter = Offset(
      math.cos(dotAngle) * radius * 0.72,
      math.sin(dotAngle) * radius * 0.72,
    );
    canvas.drawCircle(
      dotCenter,
      size.width * 0.055,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      dotCenter,
      size.width * 0.03,
      Paint()..color = AppColors.pinkDark,
    );

    final petalPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 - math.pi / 2;
      final petalCenter = Offset(
        math.cos(angle) * radius * 0.28,
        math.sin(angle) * radius * 0.28,
      );
      canvas.drawCircle(petalCenter, size.width * 0.07, petalPaint);
    }

    canvas.drawCircle(
      Offset.zero,
      size.width * 0.1,
      Paint()..color = AppColors.pinkDark,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
