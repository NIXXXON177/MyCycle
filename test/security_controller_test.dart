import 'package:flutter_test/flutter_test.dart';
import 'package:florea/core/security/security_controller.dart';
import 'package:florea/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityController', () {
    late SharedPreferences prefs;
    late SettingsService settings;
    late SecurityController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = SettingsService(prefs);
      controller = SecurityController(settings);
    });

    test('starts locked when PIN is enabled', () async {
      await settings.setPin(enabled: true, code: '1234');
      final locked = SecurityController(settings);

      expect(locked.state.pinEnabled, isTrue);
      expect(locked.state.unlocked, isFalse);
      expect(locked.state.lockRequired, isTrue);
    });

    test('starts unlocked when PIN is disabled', () {
      expect(controller.state.pinEnabled, isFalse);
      expect(controller.state.unlocked, isTrue);
      expect(controller.state.lockRequired, isFalse);
    });

    test('verifyPin accepts only saved code', () async {
      await controller.enablePin('5678');

      expect(controller.verifyPin('5678'), isTrue);
      expect(controller.verifyPin('0000'), isFalse);
    });

    test('unlock opens session after correct flow', () async {
      await controller.enablePin('1111');
      final fresh = SecurityController(settings);

      expect(fresh.state.lockRequired, isTrue);
      expect(fresh.verifyPin('1111'), isTrue);
      fresh.unlock();
      expect(fresh.state.unlocked, isTrue);
      expect(fresh.state.lockRequired, isFalse);
    });

    test('lock blocks session again', () async {
      await controller.enablePin('4321');
      controller.unlock();
      controller.lock();

      expect(controller.state.lockRequired, isTrue);
    });

    test('disablePin clears biometric and unlocks', () async {
      await controller.enablePin('9999');
      await controller.setBiometricEnabled(true);
      await controller.disablePin();

      expect(controller.state.pinEnabled, isFalse);
      expect(controller.state.biometricEnabled, isFalse);
      expect(controller.state.unlocked, isTrue);
      expect(settings.biometricEnabled, isFalse);
    });
  });
}
