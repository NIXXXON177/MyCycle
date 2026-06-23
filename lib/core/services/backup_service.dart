import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:florea/core/backup/backup_export_preview.dart';
import 'package:florea/core/backup/backup_constants.dart';
import 'package:florea/core/backup/backup_storage_errors.dart';
import 'package:florea/core/backup/backup_device_platform.dart';
import 'package:florea/core/backup/backup_manifest.dart';
import 'package:florea/core/backup/backup_settings_snapshot.dart';
import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/core/database/database_schema.dart';
import 'package:florea/core/services/diary_image_storage.dart';
import 'package:florea/core/services/settings_service.dart';
import 'package:florea/features/diary/data/datasources/diary_image_local_datasource.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Экспорт и безопасное восстановление данных Florea (Backup v2).
class BackupService {
  BackupService({
    required AppDatabase db,
    required SettingsService settings,
    DiaryImageStorage? imageStorage,
    Future<String> Function()? documentsDirectory,
  })  : _db = db,
        _settings = settings,
        _imageStorage = imageStorage ?? const DiaryImageStorage(),
        _documentsDirectory = documentsDirectory;

  final AppDatabase _db;
  final SettingsService _settings;
  final DiaryImageStorage _imageStorage;
  final Future<String> Function()? _documentsDirectory;

  /// Оценка содержимого и размера будущей резервной копии.
  Future<BackupExportPreview> previewExport() async {
    final database = await _db.database;
    final diaryEntries = await _countTable(database, DbTables.diary);
    final wellbeingEntries = await _countTable(database, DbTables.wellbeing);
    final cycles = await _countTable(database, DbTables.cycles);

    final imageDataSource = DiaryImageLocalDataSource(_db);
    final images = await imageDataSource.getAll();

    var photos = 0;
    var photosBytes = 0;
    for (final image in images) {
      final file = File(image.imagePath);
      if (!await file.exists()) continue;
      photos++;
      photosBytes += await file.length();
    }

    final dbPath = await _db.databasePath;
    final dbBytes = await File(dbPath).length();
    const metadataBytes = 4096;
    const zipFactor = 0.92;
    final estimatedBytes =
        ((dbBytes + photosBytes + metadataBytes) * zipFactor).round();

    return BackupExportPreview(
      estimatedBytes: estimatedBytes,
      diaryEntries: diaryEntries,
      photos: photos,
      wellbeingEntries: wellbeingEntries,
      cycles: cycles,
    );
  }

  Future<int> _countTable(Database database, String table) async {
    final result = await database.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return (result.first['c'] as int?) ?? 0;
  }

  /// Собирает ZIP-архив резервной копии (для тестов и внутреннего использования).
  Future<List<int>> buildBackupArchive({required String appVersion}) async {
    if (!await _isDatabaseHealthy()) {
      throw const BackupException('База повреждена, экспорт отменён');
    }

    try {
      final archive = Archive();
      final dbPath = await _db.databasePath;
      final dbBytes = await File(dbPath).readAsBytes();
      archive.addFile(
        ArchiveFile(BackupConstants.databaseFile, dbBytes.length, dbBytes),
      );

      final imageDataSource = DiaryImageLocalDataSource(_db);
      final images = await imageDataSource.getAll();
      var photosCopied = 0;

      for (final image in images) {
        final source = File(image.imagePath);
        if (!await source.exists()) continue;
        final ext = p.extension(image.imagePath);
        final archiveName =
            '${BackupConstants.imagesDir}/$photosCopied${ext.isEmpty ? '.jpg' : ext}';
        final bytes = await source.readAsBytes();
        archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
        photosCopied++;
      }

      final manifest = BackupManifest(
        appVersion: appVersion,
        createdAt: DateTime.now().toUtc(),
        photosCount: photosCopied,
        databaseVersion: DatabaseSchema.version,
        devicePlatform: BackupDevicePlatform.current(),
      );
      final manifestBytes = utf8.encode(manifest.toJsonString());
      archive.addFile(
        ArchiveFile(
          BackupConstants.manifestFile,
          manifestBytes.length,
          manifestBytes,
        ),
      );

      final settingsBytes = utf8.encode(
        BackupSettingsSnapshot.encode(BackupSettingsSnapshot.export(_settings)),
      );
      archive.addFile(
        ArchiveFile(
          BackupConstants.settingsFile,
          settingsBytes.length,
          settingsBytes,
        ),
      );

      return ZipEncoder().encode(archive);
    } catch (e) {
      BackupStorageErrors.rethrowIfInsufficientSpace(
        e,
        BackupStorageErrors.exportMessage,
      );
    }
  }

  /// Восстанавливает данные из ZIP-байтов (для тестов).
  Future<void> restoreBackupArchive(List<int> zipBytes) async {
    final extractDir = await _createTempDir('mycycle_import_');
    final rollbackDir = await _createTempDir('mycycle_rollback_');
    final settingsSnapshot = BackupSettingsSnapshot.export(_settings);

    try {
      final tempZip = File(
        p.join(extractDir, 'backup.zip'),
      );
      await tempZip.writeAsBytes(zipBytes);
      await _extractZip(tempZip.path, extractDir);
      await _validateExtractedBackup(extractDir);
      await _backupCurrentState(rollbackDir);
      await _db.close();
      try {
        await _replaceDatabase(
          p.join(extractDir, BackupConstants.databaseFile),
        );
        await _imageStorage.clearAll();
        await _remapImagePaths(extractDir);
        await _restoreSettingsFromExtracted(extractDir);
      } catch (e) {
        await _rollbackFrom(rollbackDir, settingsSnapshot);
        if (e is BackupException) rethrow;
        throw BackupException('Восстановление не завершилось: $e');
      }
    } catch (e) {
      BackupStorageErrors.rethrowIfInsufficientSpace(
        e,
        BackupStorageErrors.restoreMessage,
      );
    } finally {
      await _deleteDirectory(extractDir);
      await _deleteDirectory(rollbackDir);
    }
  }

  /// Экспорт полной резервной копии в ZIP (Backup v2).
  Future<String?> exportBackup({required String appVersion}) async {
    try {
      final zipBytes = await buildBackupArchive(appVersion: appVersion);
      final dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'Florea_Backup_$dateLabel.zip';

      return FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить резервную копию',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );
    } catch (e) {
      BackupStorageErrors.rethrowIfInsufficientSpace(
        e,
        BackupStorageErrors.exportMessage,
      );
    }
  }

  /// Импорт ZIP (Backup v2) с откатом при ошибке.
  Future<BackupImportResult> importBackupZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) {
      return BackupImportResult.cancelled;
    }

    final zipPath = result.files.single.path;
    if (zipPath == null) return BackupImportResult.cancelled;

    final extractDir = await _createTempDir('mycycle_import_');
    final rollbackDir = await _createTempDir('mycycle_rollback_');
    final settingsSnapshot = BackupSettingsSnapshot.export(_settings);

    try {
      await _extractZip(zipPath, extractDir);
      await _validateExtractedBackup(extractDir);

      await _backupCurrentState(rollbackDir);

      await _db.close();
      try {
        await _replaceDatabase(
          p.join(extractDir, BackupConstants.databaseFile),
        );
        await _imageStorage.clearAll();
        await _remapImagePaths(extractDir);
        await _restoreSettingsFromExtracted(extractDir);
      } catch (e) {
        await _rollbackFrom(rollbackDir, settingsSnapshot);
        if (e is BackupException) rethrow;
        throw BackupException('Восстановление не завершилось: $e');
      }

      return BackupImportResult.success;
    } catch (e) {
      BackupStorageErrors.rethrowIfInsufficientSpace(
        e,
        BackupStorageErrors.restoreMessage,
      );
    } finally {
      await _deleteDirectory(extractDir);
      await _deleteDirectory(rollbackDir);
    }
  }

  /// Импорт старого формата (.db) без фото и настроек.
  Future<BackupImportResult> importLegacyDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.isEmpty) {
      return BackupImportResult.cancelled;
    }

    final pickedPath = result.files.single.path;
    if (pickedPath == null) return BackupImportResult.cancelled;

    final pickedFile = File(pickedPath);
    if (!await _isSqliteFile(pickedFile)) {
      throw const BackupException('Файл не является базой данных Florea');
    }

    final rollbackDir = await _createTempDir('mycycle_legacy_rollback_');
    final settingsSnapshot = BackupSettingsSnapshot.export(_settings);

    try {
      await _backupCurrentState(rollbackDir);
      await _db.close();
      try {
        final dbPath = await _db.databasePath;
        await pickedFile.copy(dbPath);
        await _db.reopen();
        if (!await _isDatabaseHealthy()) {
          throw const BackupException('Восстановленная база повреждена');
        }
      } catch (e) {
        await _rollbackFrom(rollbackDir, settingsSnapshot);
        rethrow;
      }
      return BackupImportResult.legacySuccess;
    } finally {
      await _deleteDirectory(rollbackDir);
    }
  }

  Future<void> _validateExtractedBackup(String extractDir) async {
    final manifestFile = File(p.join(extractDir, BackupConstants.manifestFile));
    if (!await manifestFile.exists()) {
      throw const BackupException(
        'Восстановление невозможно. Резервная копия повреждена.',
      );
    }

    final manifest = BackupManifest.parse(await manifestFile.readAsString());
    manifest.validate();

    final dbFile = File(p.join(extractDir, BackupConstants.databaseFile));
    if (!await dbFile.exists()) {
      throw const BackupException(
        'Восстановление невозможно. Резервная копия повреждена.',
      );
    }
    if (!await _isSqliteFile(dbFile)) {
      throw const BackupException(
        'Восстановление невозможно. Резервная копия повреждена.',
      );
    }
    if (!await _isSqliteFileHealthy(dbFile.path)) {
      throw const BackupException(
        'Восстановление невозможно. Резервная копия повреждена.',
      );
    }

    final settingsFile = File(p.join(extractDir, BackupConstants.settingsFile));
    if (!await settingsFile.exists()) {
      throw const BackupException(
        'Восстановление невозможно. Резервная копия повреждена.',
      );
    }
    BackupSettingsSnapshot.decode(await settingsFile.readAsString());
  }

  Future<void> _backupCurrentState(String rollbackDir) async {
    final dbPath = await _db.databasePath;
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.copy(p.join(rollbackDir, BackupConstants.databaseFile));
    }
    await _imageStorage.backupTo(rollbackDir);
  }

  Future<void> _rollbackFrom(
    String rollbackDir,
    Map<String, dynamic> settingsSnapshot,
  ) async {
    await _db.close();
    final dbPath = await _db.databasePath;
    final backupDb = File(p.join(rollbackDir, BackupConstants.databaseFile));
    if (await backupDb.exists()) {
      final target = File(dbPath);
      if (await target.exists()) {
        await target.delete();
      }
      await backupDb.copy(dbPath);
    }
    await _imageStorage.restoreFromBackupDir(rollbackDir);
    await _db.reopen();
    await BackupSettingsSnapshot.restore(_settings, settingsSnapshot);
  }

  Future<void> _replaceDatabase(String sourcePath) async {
    final dbPath = await _db.databasePath;
    final target = File(dbPath);
    if (await target.exists()) {
      await target.delete();
    }
    await File(sourcePath).copy(dbPath);
    await _db.reopen();
    if (!await _isDatabaseHealthy()) {
      throw const BackupException('Восстановленная база повреждена');
    }
  }

  Future<void> _restoreSettingsFromExtracted(String extractDir) async {
    final raw = await File(
      p.join(extractDir, BackupConstants.settingsFile),
    ).readAsString();
    await BackupSettingsSnapshot.restore(
      _settings,
      BackupSettingsSnapshot.decode(raw),
    );
  }

  /// Пересоздаёт пути к фото после восстановления на новом устройстве.
  Future<void> _remapImagePaths(String extractDir) async {
    final imageDataSource = DiaryImageLocalDataSource(_db);
    final images = await imageDataSource.getAll();
    if (images.isEmpty) return;

    final extractedImages = Directory(
      p.join(extractDir, BackupConstants.imagesDir),
    );
    if (!await extractedImages.exists()) return;

    final files = <File>[];
    await for (final entity in extractedImages.list()) {
      if (entity is File) files.add(entity);
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    final database = await _db.database;
    for (var i = 0; i < images.length && i < files.length; i++) {
      final image = images[i];
      final newPath = await _imageStorage.saveFromPath(files[i].path);
      await database.update(
        DbTables.diaryImages,
        {'image_path': newPath},
        where: 'id = ?',
        whereArgs: [image.id],
      );
    }
  }

  Future<void> _extractZip(String zipPath, String targetDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      if (!file.isFile || file.name.endsWith('/')) continue;
      final outPath = p.join(targetDir, file.name);
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  Future<bool> _isDatabaseHealthy() async {
    try {
      final db = await _db.database;
      final res = await db.rawQuery('PRAGMA integrity_check');
      return res.isNotEmpty && res.first.values.first == 'ok';
    } on DatabaseException {
      return false;
    }
  }

  Future<bool> _isSqliteFileHealthy(String path) async {
    Database? db;
    try {
      db = await openDatabase(path, readOnly: true);
      final res = await db.rawQuery('PRAGMA integrity_check');
      return res.isNotEmpty && res.first.values.first == 'ok';
    } on DatabaseException {
      return false;
    } finally {
      await db?.close();
    }
  }

  Future<bool> _isSqliteFile(File file) async {
    if (!await file.exists()) return false;
    final raf = await file.open();
    try {
      final header = await raf.read(BackupConstants.sqliteMagic.length);
      if (header.length < BackupConstants.sqliteMagic.length) return false;
      for (var i = 0; i < BackupConstants.sqliteMagic.length; i++) {
        if (header[i] != BackupConstants.sqliteMagic[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  Future<String> _createTempDir(String prefix) async {
    final base = _documentsDirectory != null
        ? await _documentsDirectory()
        : Directory.systemTemp.path;
    final dir = Directory(
      p.join(base, '$prefix${DateTime.now().millisecondsSinceEpoch}'),
    );
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> _deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
