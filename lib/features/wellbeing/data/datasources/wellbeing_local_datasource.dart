import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/wellbeing/data/models/wellbeing_model.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:sqflite/sqflite.dart';

class WellbeingLocalDataSource {
  WellbeingLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<WellbeingEntry>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.wellbeing,
      orderBy: 'date DESC',
    );
    return maps.map(WellbeingModel.fromMap).toList();
  }

  Future<WellbeingEntry?> getByDate(DateTime date) async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.wellbeing,
      where: 'date = ?',
      whereArgs: [AppDateUtils.dateToIso(date)],
    );
    if (maps.isEmpty) return null;
    return WellbeingModel.fromMap(maps.first);
  }

  Future<void> upsert(WellbeingEntry entry) async {
    final database = await _db.database;
    await database.insert(
      DbTables.wellbeing,
      WellbeingModel.toMap(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.wellbeing,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
