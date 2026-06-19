import 'package:mycycle/core/constants/db_tables.dart';
import 'package:mycycle/core/database/app_database.dart';
import 'package:mycycle/features/diary/data/models/diary_model.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';

class DiaryLocalDataSource {
  DiaryLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<DiaryEntry>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.diary,
      orderBy: 'date DESC',
    );
    return maps.map(DiaryModel.fromMap).toList();
  }

  Future<List<DiaryEntry>> search(String query) async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.diary,
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map(DiaryModel.fromMap).toList();
  }

  Future<DiaryEntry?> getById(String id) async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.diary,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DiaryModel.fromMap(maps.first);
  }

  Future<void> insert(DiaryEntry entry) async {
    final database = await _db.database;
    await database.insert(DbTables.diary, DiaryModel.toMap(entry));
  }

  Future<void> update(DiaryEntry entry) async {
    final database = await _db.database;
    await database.update(
      DbTables.diary,
      DiaryModel.toMap(entry),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.diary,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
