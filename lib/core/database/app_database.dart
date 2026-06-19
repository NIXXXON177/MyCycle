import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/database_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton для управления SQLite-базой данных.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mycycle.db');

    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onCreate: (db, version) async {
        for (final sql in DatabaseSchema.all) {
          await db.execute(sql);
        }
      },
    );
  }

  /// Путь к файлу базы данных.
  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'mycycle.db');
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
      DbTables.supportEvents,
      DbTables.wishes,
    ]) {
      await db.delete(table);
    }
  }
}
