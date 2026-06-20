import 'dart:io';

import 'package:mycycle/core/backup/backup_manifest.dart';

/// Распознавание ошибок нехватки места при операциях с резервной копией.
abstract final class BackupStorageErrors {
  static const exportMessage =
      'Недостаточно свободного места для создания резервной копии.';

  static const restoreMessage =
      'Недостаточно свободного места для восстановления резервной копии.';

  static bool isInsufficientSpace(Object error) {
    if (error is BackupException) return false;

    if (error is FileSystemException) {
      if (_isNoSpaceCode(error.osError?.errorCode)) return true;
      if (_messageLooksLikeNoSpace(error.message)) return true;
      if (_messageLooksLikeNoSpace(error.osError?.message)) return true;
    }

    if (error is OSError && _isNoSpaceCode(error.errorCode)) {
      return true;
    }

    return _messageLooksLikeNoSpace(error.toString());
  }

  static Never rethrowIfInsufficientSpace(
    Object error,
    String userMessage,
  ) {
    if (isInsufficientSpace(error)) {
      throw BackupException(userMessage);
    }
    throw error;
  }

  static bool _isNoSpaceCode(int? code) {
    if (code == null) return false;
    // ENOSPC (Linux/Android), ERROR_DISK_FULL (Windows), ERROR_HANDLE_DISK_FULL
    return code == 28 || code == 112 || code == 39;
  }

  static bool _messageLooksLikeNoSpace(String? message) {
    if (message == null || message.isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('no space left on device') ||
        lower.contains('not enough space') ||
        lower.contains('insufficient storage') ||
        lower.contains('disk full') ||
        lower.contains('storage full') ||
        lower.contains('недостаточно места');
  }
}
