import 'package:flutter/material.dart';
import 'package:florea/core/constants/app_colors.dart';
import 'package:florea/shared/widgets/app_logo.dart';

/// Анимированный экран загрузки при старте приложения.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.message = 'Загрузка...'});

  final String message;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _fadeController;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF5FA),
            Color(0xFFF3E8FF),
            Color(0xFFFFFBFE),
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(
                size: 132,
                animate: true,
                animation: _logoAnimation,
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.pinkDark, AppColors.purpleDark],
                ).createShader(bounds),
                child: const Text(
                  'Florea',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'твой цикл под контролем',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray.withValues(alpha: 0.65),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 40),
              _LoadingDots(animation: _logoAnimation),
              const SizedBox(height: 12),
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.gray.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (animation.value + index * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * Curves.easeInOut.transform(phase);
            final opacity = 0.35 + 0.65 * Curves.easeInOut.transform(phase);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pinkDark.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
