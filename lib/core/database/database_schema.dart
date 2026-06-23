import 'package:florea/core/constants/db_tables.dart';

/// SQL-схема базы данных Florea.
abstract final class DatabaseSchema {
  static const int version = 5;

  static const String createCycles = '''
    CREATE TABLE ${DbTables.cycles} (
      id TEXT PRIMARY KEY,
      start_date TEXT NOT NULL,
      end_date TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String createWellbeing = '''
    CREATE TABLE ${DbTables.wellbeing} (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL UNIQUE,
      mood INTEGER NOT NULL,
      energy INTEGER NOT NULL,
      pain INTEGER NOT NULL,
      pain_locations TEXT,
      note TEXT,
      intimacy INTEGER NOT NULL DEFAULT 0,
      pms_symptoms TEXT
    )
  ''';

  static const String migrateV1ToV2 = '''
    ALTER TABLE ${DbTables.wellbeing}
    ADD COLUMN intimacy INTEGER NOT NULL DEFAULT 0
  ''';

  static const String migrateV2ToV3 = '''
    ALTER TABLE ${DbTables.wellbeing}
    ADD COLUMN pms_symptoms TEXT
  ''';

  static const String createDiary = '''
    CREATE TABLE ${DbTables.diary} (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      text TEXT NOT NULL,
      mood INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_favorite INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String createDiaryImages = '''
    CREATE TABLE ${DbTables.diaryImages} (
      id TEXT PRIMARY KEY,
      diary_id TEXT NOT NULL,
      image_path TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String createSupportEvents = '''
    CREATE TABLE ${DbTables.supportEvents} (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String createWishes = '''
    CREATE TABLE ${DbTables.wishes} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      link TEXT,
      priority INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String createImportantDates = '''
    CREATE TABLE ${DbTables.importantDates} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      repeat_yearly INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''';

  static const List<String> all = [
    createCycles,
    createWellbeing,
    createDiary,
    createDiaryImages,
    createSupportEvents,
    createWishes,
    createImportantDates,
  ];
}
