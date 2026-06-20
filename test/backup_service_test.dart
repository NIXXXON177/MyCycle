import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycycle/core/backup/backup_constants.dart';
import 'package:mycycle/core/backup/backup_manifest.dart';
import 'package:mycycle/core/backup/backup_settings_snapshot.dart';
import 'package:mycycle/core/security/pin_hasher.dart';
import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/core/services/backup_service.dart';
import 'package:mycycle/core/services/diary_image_storage.dart';
import 'package:mycycle/core/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String dbPath;
  late AppDatabase db;
  late SettingsService settings;
  late DiaryImageStorage imageStorage;
  late BackupService backupService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mycycle_backup_test_');
    dbPath = p.join(tempDir.path, 'mycycle.db');
    db = AppDatabase.forTest(dbPath);
    await db.database;

    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'pin_enabled': true,
      'pin_code': '1234',
      'biometric_enabled': true,
      'default_cycle_length': 30,
      'default_period_length': 6,
      'reminder_period_approaching': true,
      'reminder_period_start': false,
      'reminder_daily_wellbeing': true,
      'reminder_hour': 10,
      'reminder_minute': 30,
    });
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    imageStorage = DiaryImageStorage(baseDirectory: tempDir.path);
    backupService = BackupService(
      db: db,
      settings: settings,
      imageStorage: imageStorage,
      documentsDirectory: () async => tempDir.path,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } on FileSystemException {
        // Windows may keep SQLite handles briefly open.
      }
    }
  });

  group('BackupService', () {
    test('buildBackupArchive creates valid zip structure', () async {
      await _seedDatabase(db, imageStorage);

      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names = archive.files.map((f) => f.name).toSet();

      expect(names, contains(BackupConstants.manifestFile));
      expect(names, contains(BackupConstants.settingsFile));
      expect(names, contains(BackupConstants.databaseFile));
      expect(names, contains('${BackupConstants.imagesDir}/0.jpg'));

      final manifest = BackupManifest.parse(
        utf8.decode(
          archive.files
              .firstWhere((f) => f.name == BackupConstants.manifestFile)
              .content as List<int>,
        ),
      );
      expect(manifest.backupVersion, BackupConstants.backupVersion);
      expect(manifest.photosCount, 1);
      expect(manifest.databaseVersion, 5);
      expect(manifest.devicePlatform, isNotNull);
    });

    test('export stores pinHash not plaintext pinCode', () async {
      await settings.setPin(enabled: true, code: '1234');
      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final settingsFile = archive.files.firstWhere(
        (f) => f.name == BackupConstants.settingsFile,
      );
      final settingsJson =
          BackupSettingsSnapshot.decode(utf8.decode(settingsFile.content));

      expect(settingsJson, isNot(contains('pinCode')));
      expect(settingsJson['pinHash'], PinHasher.hash('1234'));
    });

    test('restore accepts legacy pinCode in settings.json', () async {
      await settings.setPin(enabled: true, code: '5678');
      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final rebuilt = Archive();
      for (final file in archive) {
        if (file.name == BackupConstants.settingsFile) {
          final legacy = BackupSettingsSnapshot.decode(
            utf8.decode(file.content),
          );
          legacy.remove('pinHash');
          legacy['pinCode'] = '5678';
          final bytes = utf8.encode(BackupSettingsSnapshot.encode(legacy));
          rebuilt.addFile(ArchiveFile(file.name, bytes.length, bytes));
        } else {
          rebuilt.addFile(file);
        }
      }
      final legacyZip = ZipEncoder().encode(rebuilt)!;

      await settings.removePin();
      await backupService.restoreBackupArchive(legacyZip);

      expect(settings.pinEnabled, isTrue);
      expect(settings.verifyPin('5678'), isTrue);
      expect(settings.biometricEnabled, isFalse);
    });

    test('previewExport reports counts and estimated size', () async {
      await _seedDatabase(db, imageStorage);
      final preview = await backupService.previewExport();

      expect(preview.diaryEntries, 1);
      expect(preview.photos, 1);
      expect(preview.cycles, 1);
      expect(preview.estimatedBytes, greaterThan(0));
      expect(preview.formattedSize, startsWith('~'));
    });

    test('restoreBackupArchive restores db, photos and settings', () async {
      await _seedDatabase(db, imageStorage);
      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );

      await db.clearAll();
      await imageStorage.clearAll();
      await settings.removePin();
      await settings.setThemeMode(ThemeMode.light);
      await db.close();

      final restoreDb = AppDatabase.forTest(dbPath);
      final restoreService = BackupService(
        db: restoreDb,
        settings: settings,
        imageStorage: imageStorage,
        documentsDirectory: () async => tempDir.path,
      );
      await restoreService.restoreBackupArchive(zipBytes);

      final database = await restoreDb.database;
      final cycles = await database.query(DbTables.cycles);
      final diary = await database.query(DbTables.diary);
      final images = await database.query(DbTables.diaryImages);

      expect(cycles, hasLength(1));
      expect(diary, hasLength(1));
      expect(diary.first['is_favorite'], 1);
      expect(images, hasLength(1));
      expect(File(images.first['image_path'] as String).existsSync(), isTrue);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.pinEnabled, isTrue);
      expect(settings.verifyPin('1234'), isTrue);
      expect(settings.biometricEnabled, isFalse);
      await restoreDb.close();
    });

    test('restore rolls back when archive database is invalid', () async {
      await _seedDatabase(db, imageStorage);
      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final rebuilt = Archive();
      for (final file in archive) {
        if (file.name == BackupConstants.databaseFile) {
          rebuilt.addFile(
            ArchiveFile(file.name, 4, [0, 1, 2, 3]),
          );
        } else {
          rebuilt.addFile(file);
        }
      }
      final brokenZip = ZipEncoder().encode(rebuilt)!;

      expect(
        () => backupService.restoreBackupArchive(brokenZip),
        throwsA(isA<BackupException>()),
      );

      final database = await db.database;
      final cycles = await database.query(DbTables.cycles);
      expect(cycles, hasLength(1));
      expect(settings.verifyPin('1234'), isTrue);
    });
  });
}

Future<void> _seedDatabase(
  AppDatabase db,
  DiaryImageStorage imageStorage,
) async {
  final database = await db.database;
  await database.insert(DbTables.cycles, {
    'id': 'cycle-1',
    'start_date': '2026-01-01T00:00:00.000',
    'end_date': '2026-01-05T00:00:00.000',
    'created_at': '2026-01-01T00:00:00.000',
  });
  await database.insert(DbTables.diary, {
    'id': 'diary-1',
    'date': '2026-02-01T00:00:00.000',
    'text': 'Backup test entry',
    'mood': 4,
    'created_at': '2026-02-01T00:00:00.000',
    'updated_at': '2026-02-01T00:00:00.000',
    'is_favorite': 1,
  });

  final imageDir = await imageStorage.imagesDirectory;
  final imageFile = File(p.join(imageDir, 'seed.jpg'));
  await imageFile.writeAsBytes(const [1, 2, 3, 4]);
  await database.insert(DbTables.diaryImages, {
    'id': 'img-1',
    'diary_id': 'diary-1',
    'image_path': imageFile.path,
    'created_at': '2026-02-01T00:00:00.000',
  });
}
