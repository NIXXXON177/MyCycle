@Tags(['benchmark'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:florea/core/backup/backup_export_preview.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/core/services/backup_service.dart';
import 'package:florea/core/services/diary_image_storage.dart';
import 'package:florea/core/services/settings_service.dart';
import 'package:florea/core/services/stress_test_seeder.dart';
import 'package:florea/core/utils/cycle_calculator.dart';
import 'package:florea/features/cycle/data/datasources/cycle_local_datasource.dart';
import 'package:florea/features/cycle/data/repositories/cycle_repository.dart';
import 'package:florea/features/diary/data/datasources/diary_image_local_datasource.dart';
import 'package:florea/features/diary/data/datasources/diary_local_datasource.dart';
import 'package:florea/features/diary/data/repositories/diary_repository.dart';
import 'package:florea/features/important_dates/data/datasources/important_date_local_datasource.dart';
import 'package:florea/features/important_dates/data/repositories/important_date_repository.dart';
import 'package:florea/features/support/data/datasources/support_local_datasource.dart';
import 'package:florea/features/support/data/repositories/support_repository.dart';
import 'package:florea/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:florea/features/wellbeing/data/repositories/wellbeing_repository.dart';
import 'package:florea/features/wishes/data/datasources/wish_local_datasource.dart';
import 'package:florea/features/wishes/data/repositories/wish_repository.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Стресс-бенчмарк Backup v2: 300 фото, 1000 дневник, 500 самочувствие.
///
/// Запуск: `flutter test --tags benchmark`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase db;
  late SettingsService settings;
  late DiaryImageStorage imageStorage;
  late BackupService backupService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mycycle_benchmark_');
    final dbPath = p.join(tempDir.path, 'mycycle.db');
    db = AppDatabase.forTest(dbPath);
    await db.database;

    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
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
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'stress dataset export and restore benchmarks',
    () async {
      final calculator = CycleCalculator(
        defaultCycleLength: settings.defaultCycleLength,
        defaultPeriodLength: settings.defaultPeriodLength,
      );
      final seeder = StressTestSeeder(
        cycleRepo: CycleRepository(CycleLocalDataSource(db), calculator),
        wellbeingRepo:
            WellbeingRepository(WellbeingLocalDataSource(db)),
        diaryRepo: DiaryRepository(
          DiaryLocalDataSource(db),
          DiaryImageLocalDataSource(db),
          imageStorage,
        ),
        supportRepo: SupportRepository(SupportLocalDataSource(db)),
        wishRepo: WishRepository(WishLocalDataSource(db)),
        importantDateRepo: ImportantDateRepository(
          ImportantDateLocalDataSource(db),
        ),
        imageStorage: imageStorage,
      );

      final seedStopwatch = Stopwatch()..start();
      await seeder.generate();
      seedStopwatch.stop();

      final preview = await backupService.previewExport();
      expect(preview.photos, StressTestSeeder.photoCount);
      expect(preview.diaryEntries, StressTestSeeder.diaryCount);
      expect(preview.wellbeingEntries, StressTestSeeder.wellbeingCount);

      final exportStopwatch = Stopwatch()..start();
      final zipBytes = await backupService.buildBackupArchive(
        appVersion: '1.7.5',
      );
      exportStopwatch.stop();

      final archiveSize = zipBytes.length;
      final archiveMb = archiveSize / (1024 * 1024);

      await db.close();
      final restoreDbPath = p.join(tempDir.path, 'mycycle_restored.db');
      final restoreDb = AppDatabase.forTest(restoreDbPath);
      final restoreService = BackupService(
        db: restoreDb,
        settings: settings,
        imageStorage: imageStorage,
        documentsDirectory: () async => tempDir.path,
      );

      final restoreStopwatch = Stopwatch()..start();
      await restoreService.restoreBackupArchive(zipBytes);
      restoreStopwatch.stop();
      await restoreDb.close();

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('=== Backup v2 stress benchmark (desktop FFI) ===');
      // ignore: avoid_print
      print('Dataset: ${StressTestSeeder.photoCount} photos, '
          '${StressTestSeeder.diaryCount} diary, '
          '${StressTestSeeder.wellbeingCount} wellbeing');
      // ignore: avoid_print
      print('Seed: ${seedStopwatch.elapsedMilliseconds} ms');
      // ignore: avoid_print
      print('Export: ${exportStopwatch.elapsedMilliseconds} ms');
      // ignore: avoid_print
      print('Archive size: ${archiveMb.toStringAsFixed(2)} MB '
          '(${BackupExportPreview.formatBackupSize(archiveSize)})');
      // ignore: avoid_print
      print('Restore: ${restoreStopwatch.elapsedMilliseconds} ms');
      // ignore: avoid_print
      print('Preview estimate: ${preview.formattedSize} '
          '(peak ~${preview.formattedTemporarySpace})');
      // ignore: avoid_print
      print('================================================');
      // ignore: avoid_print
      print('');

      expect(archiveSize, greaterThan(0));
      expect(exportStopwatch.elapsedMilliseconds, lessThan(300000));
      expect(restoreStopwatch.elapsedMilliseconds, lessThan(300000));
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
