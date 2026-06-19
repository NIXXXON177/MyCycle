import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycycle/core/constants/app_colors.dart';
import 'package:mycycle/shared/widgets/app_logo.dart';
import 'package:mycycle/core/providers/app_providers.dart';
import 'package:mycycle/core/router/app_router.dart';

/// Экран ввода PIN-кода при запуске.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;

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
              Row(
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
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.period)),
              ],
              const SizedBox(height: 48),
              _buildNumpad(),
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
    final settings = ref.read(settingsServiceProvider);
    if (settings.verifyPin(_pin)) {
      context.go(AppRoutes.home);
    } else {
      setState(() {
        _error = 'Неверный PIN';
        _pin = '';
      });
    }
  }
}
