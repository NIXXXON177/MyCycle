import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:path/path.dart' as p;

/// Сервис резервного копирования SQLite-базы.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<String?> exportDatabase() async {
    final dbPath = await _db.databasePath;
    final source = File(dbPath);
    if (!await source.exists()) return null;

    final fileName =
        'mycycle_backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить резервную копию',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null) return null;

    await source.copy(result);
    return result;
  }

  Future<bool> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null || result.files.single.path == null) return false;

    final pickedPath = result.files.single.path!;
    final dbPath = await _db.databasePath;

    await _db.close();
    await File(pickedPath).copy(dbPath);
    await _db.reopen();

    return true;
  }
}
