import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/security/security_controller.dart';
import 'package:mycycle/shared/widgets/app_logo.dart';

/// Экран ввода PIN-кода при запуске.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Автоматически предлагаем биометрию при запуске, если она включена.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(securityProvider).biometricEnabled) {
        _tryBiometric();
      }
    });
  }

  Future<void> _tryBiometric() async {
    if (!ref.read(securityProvider).biometricEnabled) return;
    final service = ref.read(biometricServiceProvider);
    if (!await service.isAvailable()) return;
    final ok = await service.authenticate();
    if (ok && mounted) {
      HapticFeedback.lightImpact();
      ref.read(securityProvider.notifier).unlock();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 96),
              const SizedBox(height: 16),
              Text(
                'MyCycle',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.pinkDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Введите PIN-код'),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx = math.sin(_shake.value * math.pi * 4) *
                      12 *
                      (1 - _shake.value);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? AppColors.pinkDark
                            : AppColors.lightGray,
                      ),
                    );
                  }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.period)),
              ],
              const SizedBox(height: 48),
              _buildNumpad(),
              if (ref.watch(securityProvider).biometricEnabled) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Войти по биометрии'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox();

        return TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            if (key == '⌫') {
              setState(() {
                if (_pin.isNotEmpty) {
                  _pin = _pin.substring(0, _pin.length - 1);
                }
                _error = null;
              });
            } else if (_pin.length < 4) {
              setState(() => _pin += key);
              if (_pin.length == 4) _verify();
            }
          },
          child: Text(
            key,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      },
    );
  }

  void _verify() {
    final security = ref.read(securityProvider.notifier);
    if (security.verifyPin(_pin)) {
      HapticFeedback.lightImpact();
      security.unlock();
    } else {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _error = 'Неверный PIN';
        _pin = '';
      });
    }
  }
}
