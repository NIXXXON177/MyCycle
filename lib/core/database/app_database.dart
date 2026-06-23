import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/database_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton для управления SQLite-базой данных.
class AppDatabase {
  AppDatabase._({String? testPath}) : _testPath = testPath;

  static final AppDatabase instance = AppDatabase._();

  final String? _testPath;
  Database? _db;

  /// Экземпляр с фиксированным путём (для тестов).
  factory AppDatabase.forTest(String path) => AppDatabase._(testPath: path);

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = _testPath ?? join(await getDatabasesPath(), 'mycycle.db');
    return _open(path);
  }

  static Future<Database> _open(String path) {
    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onCreate: (db, version) async {
        for (final sql in DatabaseSchema.all) {
          await db.execute(sql);
        }
      },
      onUpgrade: _runMigrations,
    );
  }

  /// Открывает БД с произвольной начальной схемой (для тестов миграций).
  static Future<Database> openLegacy({
    required String path,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
  }) {
    return openDatabase(
      path,
      version: version,
      onCreate: onCreate,
      onUpgrade: _runMigrations,
    );
  }

  /// Поднимает существующую БД до текущей версии схемы.
  static Future<Database> upgradeLegacyDatabase(String path) {
    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onUpgrade: _runMigrations,
    );
  }

  static Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(DatabaseSchema.migrateV1ToV2);
    }
    if (oldVersion < 3) {
      await db.execute(DatabaseSchema.migrateV2ToV3);
    }
    if (oldVersion < 4) {
      await db.execute(DatabaseSchema.createImportantDates);
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE ${DbTables.diary} ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(DatabaseSchema.createDiaryImages);
    }
  }

  /// Путь к файлу базы данных.
  Future<String> get databasePath async {
    return _testPath ?? join(await getDatabasesPath(), 'mycycle.db');
  }

  /// Закрывает соединение (для импорта/экспорта).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Переоткрывает базу после замены файла.
  Future<void> reopen() async {
    await close();
    await database;
  }

  /// Очищает все таблицы.
  Future<void> clearAll() async {
    final db = await database;
    for (final table in [
      DbTables.cycles,
      DbTables.wellbeing,
      DbTables.diary,
      DbTables.diaryImages,
      DbTables.supportEvents,
      DbTables.wishes,
      DbTables.importantDates,
    ]) {
      await db.delete(table);
    }
  }
}
