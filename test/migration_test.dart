import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/core/database/database_schema.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/migration_schemas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mycycle_migration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Database> upgradedDb(int fromVersion) async {
    final path = p.join(tempDir.path, 'v$fromVersion.db');
    final legacyDb = await AppDatabase.openLegacy(
      path: path,
      version: fromVersion,
      onCreate: switch (fromVersion) {
        1 => MigrationSchemas.createV1,
        2 => MigrationSchemas.createV2,
        3 => MigrationSchemas.createV3,
        4 => MigrationSchemas.createV4,
        _ => throw ArgumentError('Unsupported legacy version $fromVersion'),
      },
    );
    await legacyDb.close();
    return AppDatabase.upgradeLegacyDatabase(path);
  }

  Future<void> expectCurrentSchema(Database db) async {
    expect(await db.getVersion(), DatabaseSchema.version);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = tables.map((row) => row['name'] as String).toSet();
    expect(names, contains(DbTables.importantDates));
    expect(names, contains(DbTables.diaryImages));

    final wellbeingCols = await db.rawQuery(
      'PRAGMA table_info(${DbTables.wellbeing})',
    );
    final wellbeingNames =
        wellbeingCols.map((row) => row['name'] as String).toSet();
    expect(wellbeingNames, contains('intimacy'));
    expect(wellbeingNames, contains('pms_symptoms'));

    final diaryCols = await db.rawQuery(
      'PRAGMA table_info(${DbTables.diary})',
    );
    final diaryNames = diaryCols.map((row) => row['name'] as String).toSet();
    expect(diaryNames, contains('is_favorite'));
  }

  group('Database migrations', () {
    for (final version in [1, 2, 3, 4]) {
      test('upgrades v$version to v${DatabaseSchema.version}', () async {
        Database? db;
        try {
          db = await upgradedDb(version);
          await expectCurrentSchema(db);
        } finally {
          await db?.close();
        }
      });
    }
  });
}
