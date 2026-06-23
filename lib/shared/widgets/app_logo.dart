import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:florea/core/constants/app_colors.dart';

/// Логотип Florea — цикл с маркером дня.
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
    final w = size.width;
    final center = Offset(w / 2, size.height / 2);
    final radius = w * 0.42;
    // Едва заметное «дыхание» — спокойнее прежнего.
    final breathe = 0.99 + 0.01 * math.sin(progress * math.pi * 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(breathe);

    // Мягкая тень под кругом.
    final shadow = Paint()
      ..color = AppColors.pinkDark.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(const Offset(0, 8), radius * 0.94, shadow);

    // Градиентный круг-основа.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.pink, AppColors.purple],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, bg);

    // Лёгкий блик сверху для объёма.
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, glow);

    final ringRadius = radius * 0.66;
    final stroke = w * 0.052;
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: ringRadius);

    // Тонкое кольцо-трек цикла.
    canvas.drawCircle(
      Offset.zero,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    // Дуга-«комета»: яркая у точки и затухающая к хвосту.
    final headAngle = -math.pi / 2 + progress * math.pi * 2;
    const trail = math.pi * 1.5;
    canvas.drawArc(
      ringRect,
      headAngle - trail,
      trail,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: trail,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.95),
          ],
          transform: GradientRotation(headAngle - trail),
        ).createShader(ringRect),
    );

    // Точка-день на голове дуги: белая с розовым ядром.
    final dot = Offset(
      math.cos(headAngle) * ringRadius,
      math.sin(headAngle) * ringRadius,
    );
    canvas.drawCircle(dot, w * 0.075, Paint()..color = Colors.white);
    canvas.drawCircle(dot, w * 0.038, Paint()..color = AppColors.pinkDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
