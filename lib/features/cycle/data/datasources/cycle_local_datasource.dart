import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/features/cycle/data/models/cycle_model.dart';
import 'package:mycycle/features/cycle/domain/entities/cycle.dart';

/// Источник данных циклов (SQLite).
class CycleLocalDataSource {
  CycleLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Cycle>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.cycles,
      orderBy: 'start_date DESC',
    );
    return maps.map(CycleModel.fromMap).toList();
  }

  Future<Cycle?> getById(String id) async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.cycles,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CycleModel.fromMap(maps.first);
  }

  Future<void> insert(Cycle cycle) async {
    final database = await _db.database;
    await database.insert(DbTables.cycles, CycleModel.toMap(cycle));
  }

  Future<void> update(Cycle cycle) async {
    final database = await _db.database;
    await database.update(
      DbTables.cycles,
      CycleModel.toMap(cycle),
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.cycles,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
