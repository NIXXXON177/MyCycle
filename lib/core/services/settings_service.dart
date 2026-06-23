import 'package:flutter/material.dart';
import 'package:florea/core/constants/prefs_keys.dart';
import 'package:florea/core/security/pin_hasher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Модель настроек напоминаний.
class ReminderSettings {
  const ReminderSettings({
    this.periodApproaching = true,
    this.periodStart = true,
    this.dailyWellbeing = true,
    this.hour = 9,
    this.minute = 0,
  });

  final bool periodApproaching;
  final bool periodStart;
  final bool dailyWellbeing;
  final int hour;
  final int minute;

  ReminderSettings copyWith({
    bool? periodApproaching,
    bool? periodStart,
    bool? dailyWellbeing,
    int? hour,
    int? minute,
  }) {
    return ReminderSettings(
      periodApproaching: periodApproaching ?? this.periodApproaching,
      periodStart: periodStart ?? this.periodStart,
      dailyWellbeing: dailyWellbeing ?? this.dailyWellbeing,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

/// Сервис настроек приложения (SharedPreferences).
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode get themeMode {
    final value = _prefs.getString(PrefsKeys.themeMode) ?? 'system';
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(PrefsKeys.themeMode, value);
  }

  bool get pinEnabled {
    final enabled = _prefs.getBool(PrefsKeys.pinEnabled) ?? false;
    if (!enabled) return false;
    return _prefs.containsKey(PrefsKeys.pinHash) ||
        _prefs.containsKey(PrefsKeys.pinCode);
  }

  /// SHA-256-хэш PIN для экспорта в резервную копию (без plaintext).
  String? get pinHash {
    final hash = _prefs.getString(PrefsKeys.pinHash);
    if (hash != null) return hash;
    final legacy = _prefs.getString(PrefsKeys.pinCode);
    if (legacy != null) return PinHasher.hash(legacy);
    return null;
  }

  Future<void> setPin({required bool enabled, String? code}) async {
    await _prefs.setBool(PrefsKeys.pinEnabled, enabled);
    if (code != null) {
      await _prefs.setString(PrefsKeys.pinHash, PinHasher.hash(code));
      await _prefs.remove(PrefsKeys.pinCode);
    }
  }

  /// Восстановление PIN из резервной копии (уже захэширован).
  Future<void> setPinFromHash({required bool enabled, required String hash}) async {
    await _prefs.setBool(PrefsKeys.pinEnabled, enabled);
    await _prefs.setString(PrefsKeys.pinHash, hash);
    await _prefs.remove(PrefsKeys.pinCode);
  }

  Future<void> removePin() async {
    await _prefs.setBool(PrefsKeys.pinEnabled, false);
    await _prefs.remove(PrefsKeys.pinHash);
    await _prefs.remove(PrefsKeys.pinCode);
    // Без PIN биометрическая разблокировка не имеет смысла.
    await _prefs.setBool(PrefsKeys.biometricEnabled, false);
  }

  bool verifyPin(String input) {
    final legacy = _prefs.getString(PrefsKeys.pinCode);
    if (legacy != null) {
      if (legacy != input) return false;
      // Миграция plaintext → hash после успешной проверки.
      _prefs.setString(PrefsKeys.pinHash, PinHasher.hash(legacy));
      _prefs.remove(PrefsKeys.pinCode);
      return true;
    }
    final stored = _prefs.getString(PrefsKeys.pinHash);
    if (stored == null) return false;
    return PinHasher.verify(input, stored);
  }

  bool get biometricEnabled =>
      _prefs.getBool(PrefsKeys.biometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool(PrefsKeys.biometricEnabled, value);
  }

  int get defaultCycleLength =>
      _prefs.getInt(PrefsKeys.defaultCycleLength) ?? 28;

  int get defaultPeriodLength =>
      _prefs.getInt(PrefsKeys.defaultPeriodLength) ?? 5;

  Future<void> setDefaultCycleLength(int value) async {
    await _prefs.setInt(PrefsKeys.defaultCycleLength, value);
  }

  Future<void> setDefaultPeriodLength(int value) async {
    await _prefs.setInt(PrefsKeys.defaultPeriodLength, value);
  }

  ReminderSettings get reminderSettings {
    return ReminderSettings(
      periodApproaching:
          _prefs.getBool(PrefsKeys.reminderPeriodApproaching) ?? true,
      periodStart: _prefs.getBool(PrefsKeys.reminderPeriodStart) ?? true,
      dailyWellbeing:
          _prefs.getBool(PrefsKeys.reminderDailyWellbeing) ?? true,
      hour: _prefs.getInt(PrefsKeys.reminderHour) ?? 9,
      minute: _prefs.getInt(PrefsKeys.reminderMinute) ?? 0,
    );
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    await _prefs.setBool(
      PrefsKeys.reminderPeriodApproaching,
      settings.periodApproaching,
    );
    await _prefs.setBool(
      PrefsKeys.reminderPeriodStart,
      settings.periodStart,
    );
    await _prefs.setBool(
      PrefsKeys.reminderDailyWellbeing,
      settings.dailyWellbeing,
    );
    await _prefs.setInt(PrefsKeys.reminderHour, settings.hour);
    await _prefs.setInt(PrefsKeys.reminderMinute, settings.minute);
  }

  bool get demoDataLoaded =>
      _prefs.getBool(PrefsKeys.demoDataLoaded) ?? false;

  Future<void> setDemoDataLoaded(bool value) async {
    await _prefs.setBool(PrefsKeys.demoDataLoaded, value);
  }

  bool get developerModeUnlocked =>
      _prefs.getBool(PrefsKeys.developerModeUnlocked) ?? false;

  Future<void> setDeveloperModeUnlocked(bool value) async {
    await _prefs.setBool(PrefsKeys.developerModeUnlocked, value);
  }
}
