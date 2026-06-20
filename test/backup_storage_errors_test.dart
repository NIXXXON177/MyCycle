import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mycycle/core/backup/backup_manifest.dart';
import 'package:mycycle/core/backup/backup_storage_errors.dart';

void main() {
  group('BackupStorageErrors', () {
    test('detects Linux ENOSPC by error code', () {
      final error = FileSystemException(
        'write failed',
        'backup.zip',
        const OSError('No space left on device', 28),
      );

      expect(BackupStorageErrors.isInsufficientSpace(error), isTrue);
    });

    test('detects Windows disk full by error code', () {
      final error = FileSystemException(
        'write failed',
        'backup.zip',
        const OSError('There is not enough space on the disk.', 112),
      );

      expect(BackupStorageErrors.isInsufficientSpace(error), isTrue);
    });

    test('detects no-space by message text', () {
      final error = FileSystemException(
        'No space left on device',
        'backup.zip',
      );

      expect(BackupStorageErrors.isInsufficientSpace(error), isTrue);
    });

    test('maps to user-facing export message', () {
      final error = FileSystemException(
        'No space left on device',
        'backup.zip',
      );

      expect(
        () => BackupStorageErrors.rethrowIfInsufficientSpace(
          error,
          BackupStorageErrors.exportMessage,
        ),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            BackupStorageErrors.exportMessage,
          ),
        ),
      );
    });

    test('does not mask unrelated errors', () {
      final error = StateError('unexpected');

      expect(
        () => BackupStorageErrors.rethrowIfInsufficientSpace(
          error,
          BackupStorageErrors.exportMessage,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
