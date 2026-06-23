import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:florea/core/security/pin_hasher.dart';
import 'package:florea/core/services/settings_service.dart';

/// Сериализация настроек SharedPreferences в settings.json.
abstract final class BackupSettingsSnapshot {
  static Map<String, dynamic> export(SettingsService settings) {
    final reminders = settings.reminderSettings;
    return {
      'theme': _themeToString(settings.themeMode),
      'pinEnabled': settings.pinEnabled,
      if (settings.pinHash != null) 'pinHash': settings.pinHash,
      'biometricEnabled': settings.biometricEnabled,
      'defaultCycleLength': settings.defaultCycleLength,
      'defaultPeriodLength': settings.defaultPeriodLength,
      'notificationsEnabled': reminders.periodApproaching ||
          reminders.periodStart ||
          reminders.dailyWellbeing,
      'reminderPeriodApproaching': reminders.periodApproaching,
      'reminderPeriodStart': reminders.periodStart,
      'reminderDailyWellbeing': reminders.dailyWellbeing,
      'reminderHour': reminders.hour,
      'reminderMinute': reminders.minute,
    };
  }

  static Future<void> restore(
    SettingsService settings,
    Map<String, dynamic> json,
  ) async {
    final theme = json['theme'] as String? ?? 'system';
    await settings.setThemeMode(_themeFromString(theme));

    final pinEnabled = json['pinEnabled'] as bool? ?? false;
    final pinHash = json['pinHash'] as String?;
    final legacyPinCode = json['pinCode'] as String?;
    if (pinEnabled && pinHash != null) {
      await settings.setPinFromHash(enabled: true, hash: pinHash);
    } else if (pinEnabled && legacyPinCode != null) {
      // Совместимость со старыми архивами с plaintext pinCode.
      await settings.setPinFromHash(
        enabled: true,
        hash: PinHasher.hash(legacyPinCode),
      );
    } else {
      await settings.removePin();
    }

    // Биометрические ключи привязаны к устройству — после Restore выключаем.
    if (pinEnabled) {
      await settings.setBiometricEnabled(false);
    }

    if (json['defaultCycleLength'] is int) {
      await settings.setDefaultCycleLength(json['defaultCycleLength'] as int);
    }
    if (json['defaultPeriodLength'] is int) {
      await settings.setDefaultPeriodLength(json['defaultPeriodLength'] as int);
    }

    await settings.saveReminderSettings(
      ReminderSettings(
        periodApproaching:
            json['reminderPeriodApproaching'] as bool? ?? true,
        periodStart: json['reminderPeriodStart'] as bool? ?? true,
        dailyWellbeing: json['reminderDailyWellbeing'] as bool? ?? true,
        hour: json['reminderHour'] as int? ?? 9,
        minute: json['reminderMinute'] as int? ?? 0,
      ),
    );
  }

  static String encode(Map<String, dynamic> data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  static Map<String, dynamic> decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  static String _themeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _themeFromString(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
