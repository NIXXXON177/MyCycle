import 'package:mycycle/core/constants/db_tables.dart';

/// SQL-схема базы данных MyCycle.
abstract final class DatabaseSchema {
  static const int version = 1;

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
      note TEXT
    )
  ''';

  static const String createDiary = '''
    CREATE TABLE ${DbTables.diary} (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      text TEXT NOT NULL,
      mood INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
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

  static const List<String> all = [
    createCycles,
    createWellbeing,
    createDiary,
    createSupportEvents,
    createWishes,
  ];
}
