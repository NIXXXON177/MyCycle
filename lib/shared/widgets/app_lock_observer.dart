import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/security/security_controller.dart';

/// Блокирует приложение при уходе в фон, если включён PIN.
class AppLockObserver extends ConsumerStatefulWidget {
  const AppLockObserver({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends ConsumerState<AppLockObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Только paused — не inactive (биометрический диалог даёт inactive).
    if (state == AppLifecycleState.paused) {
      ref.read(securityProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
