import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/features/important_dates/data/models/important_date_model.dart';
import 'package:florea/features/important_dates/domain/entities/important_date.dart';

class ImportantDateLocalDataSource {
  ImportantDateLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<ImportantDate>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.importantDates,
      orderBy: 'date ASC',
    );
    return maps.map(ImportantDateModel.fromMap).toList();
  }

  Future<void> insert(ImportantDate entry) async {
    final database = await _db.database;
    await database.insert(DbTables.importantDates, ImportantDateModel.toMap(entry));
  }

  Future<void> update(ImportantDate entry) async {
    final database = await _db.database;
    await database.update(
      DbTables.importantDates,
      ImportantDateModel.toMap(entry),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.importantDates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
