import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycycle/core/services/settings_service.dart';

/// Состояние блокировки приложения (PIN / биометрия).
class SecurityState {
  const SecurityState({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.unlocked,
  });

  final bool pinEnabled;
  final bool biometricEnabled;
  final bool unlocked;

  bool get lockRequired => pinEnabled && !unlocked;

  SecurityState copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? unlocked,
  }) {
    return SecurityState(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

/// Управляет PIN, биометрией и сессией разблокировки.
class SecurityController extends StateNotifier<SecurityState> {
  SecurityController(this._settings) : super(_initialState(_settings));

  final SettingsService _settings;

  static SecurityState _initialState(SettingsService settings) {
    final pinEnabled = settings.pinEnabled;
    return SecurityState(
      pinEnabled: pinEnabled,
      biometricEnabled: settings.biometricEnabled,
      // При запуске с PIN — заблокировано до ввода.
      unlocked: !pinEnabled,
    );
  }

  bool verifyPin(String input) => _settings.verifyPin(input);

  void unlock() {
    if (!state.pinEnabled) return;
    state = state.copyWith(unlocked: true);
  }

  void lock() {
    if (!state.pinEnabled) return;
    state = state.copyWith(unlocked: false);
  }

  Future<void> enablePin(String code) async {
    await _settings.setPin(enabled: true, code: code);
    state = SecurityState(
      pinEnabled: true,
      biometricEnabled: state.biometricEnabled,
      // Только что задали PIN в настройках — не блокируем текущую сессию.
      unlocked: true,
    );
  }

  Future<void> disablePin() async {
    await _settings.removePin();
    state = const SecurityState(
      pinEnabled: false,
      biometricEnabled: false,
      unlocked: true,
    );
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _settings.setBiometricEnabled(value);
    state = state.copyWith(biometricEnabled: value);
  }
}

/// Сигнал для пересчёта redirect в GoRouter.
class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
