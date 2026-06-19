import 'package:flutter/material.dart';
import 'package:mycycle/core/constants/prefs_keys.dart';
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

  bool get pinEnabled => _prefs.getBool(PrefsKeys.pinEnabled) ?? false;

  String? get pinCode => _prefs.getString(PrefsKeys.pinCode);

  Future<void> setPin({required bool enabled, String? code}) async {
    await _prefs.setBool(PrefsKeys.pinEnabled, enabled);
    if (code != null) {
      await _prefs.setString(PrefsKeys.pinCode, code);
    }
  }

  Future<void> removePin() async {
    await _prefs.setBool(PrefsKeys.pinEnabled, false);
    await _prefs.remove(PrefsKeys.pinCode);
  }

  bool verifyPin(String input) => pinCode == input;

  int get defaultCycleLength =>
      _prefs.getInt(PrefsKeys.defaultCycleLength) ?? 28;

  int get defaultPeriodLength =>
      _prefs.getInt(PrefsKeys.defaultPeriodLength) ?? 5;

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
}
