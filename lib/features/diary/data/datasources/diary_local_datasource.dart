import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/diary/data/models/diary_model.dart';
import 'package:florea/features/diary/domain/entities/diary_entry.dart';
import 'package:florea/features/diary/domain/entities/diary_list_query.dart';

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

  Future<List<DiaryEntry>> query(DiaryListQuery query) async {
    final database = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];

    if (query.text.isNotEmpty) {
      conditions.add('text LIKE ?');
      args.add('%${query.text}%');
    }
    if (query.favoritesOnly) {
      conditions.add('is_favorite = 1');
    }
    if (query.from != null) {
      conditions.add('date >= ?');
      args.add(AppDateUtils.dateToIso(query.from!));
    }
    if (query.to != null) {
      conditions.add('date <= ?');
      args.add(AppDateUtils.dateToIso(query.to!));
    }

    final maps = await database.query(
      DbTables.diary,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return maps.map(DiaryModel.fromMap).toList();
  }

  Future<List<DiaryEntry>> search(String query) async {
    return this.query(DiaryListQuery(text: query));
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
