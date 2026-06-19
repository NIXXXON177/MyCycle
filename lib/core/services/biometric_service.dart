import 'package:local_auth/local_auth.dart';

/// Биометрическая аутентификация (отпечаток/лицо) для разблокировки приложения.
class BiometricService {
  final _auth = LocalAuthentication();

  /// Доступна ли биометрия на устройстве и настроен ли хотя бы один способ.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Запрашивает биометрию. Возвращает true при успешном подтверждении.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Подтвердите вход в MyCycle',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
