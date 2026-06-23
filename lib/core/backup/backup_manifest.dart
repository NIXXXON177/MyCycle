import 'dart:convert';

import 'package:florea/core/backup/backup_constants.dart';
import 'package:florea/core/database/database_schema.dart';

/// Метаданные резервной копии (manifest.json).
class BackupManifest {
  const BackupManifest({
    required this.appVersion,
    required this.createdAt,
    required this.photosCount,
    this.backupVersion = BackupConstants.backupVersion,
    this.databaseVersion = DatabaseSchema.version,
    this.devicePlatform,
  });

  final String appVersion;
  final int backupVersion;
  final DateTime createdAt;
  final int photosCount;
  final int databaseVersion;
  final String? devicePlatform;

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'backupVersion': backupVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'photosCount': photosCount,
        'databaseVersion': databaseVersion,
        if (devicePlatform != null) 'devicePlatform': devicePlatform,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appVersion: json['appVersion'] as String? ?? 'unknown',
      backupVersion: json['backupVersion'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      photosCount: json['photosCount'] as int? ?? 0,
      databaseVersion: json['databaseVersion'] as int? ?? 1,
      devicePlatform: json['devicePlatform'] as String?,
    );
  }

  static BackupManifest parse(String raw) =>
      BackupManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  void validate() {
    if (backupVersion != BackupConstants.backupVersion) {
      throw BackupException(
        'Неподдерживаемая версия резервной копии: $backupVersion',
      );
    }
    if (databaseVersion > DatabaseSchema.version) {
      throw const BackupException(
        'Резервная копия создана в более новой версии приложения. '
        'Обновите Florea перед восстановлением.',
      );
    }
  }
}

/// Ошибка резервного копирования с текстом для пользователя.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Результат импорта резервной копии.
enum BackupImportResult {
  cancelled,
  success,
  legacySuccess,
}
