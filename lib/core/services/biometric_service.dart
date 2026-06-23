import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Биометрическая аутентификация (отпечаток/лицо) для разблокировки приложения.
class BiometricService {
  final _auth = LocalAuthentication();

  /// Доступна ли биометрия на устройстве.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Запрашивает биометрию. Возвращает true при успешном подтверждении.
  Future<bool> authenticate() async {
    try {
      if (!await isAvailable()) return false;

      return await _auth.authenticate(
        localizedReason: 'Подтвердите вход в Florea',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}
