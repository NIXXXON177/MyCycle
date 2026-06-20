import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/database_schema.dart';

/// Исторические схемы БД для тестов миграций.
abstract final class MigrationSchemas {
  static const wellbeingV1 = '''
    CREATE TABLE ${DbTables.wellbeing} (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL UNIQUE,
      mood INTEGER NOT NULL,
      energy INTEGER NOT NULL,
      pain INTEGER NOT NULL,
      pain_locations TEXT,
      note TEXT
    )
  ''';

  static const diaryV1 = '''
    CREATE TABLE ${DbTables.diary} (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      text TEXT NOT NULL,
      mood INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static Future<void> createV1(dynamic db, int version) async {
    await db.execute(DatabaseSchema.createCycles);
    await db.execute(wellbeingV1);
    await db.execute(diaryV1);
    await db.execute(DatabaseSchema.createSupportEvents);
    await db.execute(DatabaseSchema.createWishes);
  }

  static Future<void> createV2(dynamic db, int version) async {
    await createV1(db, version);
    await db.execute(DatabaseSchema.migrateV1ToV2);
  }

  static Future<void> createV3(dynamic db, int version) async {
    await createV2(db, version);
    await db.execute(DatabaseSchema.migrateV2ToV3);
  }

  static Future<void> createV4(dynamic db, int version) async {
    await createV3(db, version);
    await db.execute(DatabaseSchema.createImportantDates);
  }
}
