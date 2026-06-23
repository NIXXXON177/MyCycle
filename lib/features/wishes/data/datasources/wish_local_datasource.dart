import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/features/wishes/data/models/wish_model.dart';
import 'package:florea/features/wishes/domain/entities/wish.dart';

class WishLocalDataSource {
  WishLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Wish>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.wishes,
      orderBy: 'priority DESC, created_at DESC',
    );
    return maps.map(WishModel.fromMap).toList();
  }

  Future<void> insert(Wish wish) async {
    final database = await _db.database;
    await database.insert(DbTables.wishes, WishModel.toMap(wish));
  }

  Future<void> update(Wish wish) async {
    final database = await _db.database;
    await database.update(
      DbTables.wishes,
      WishModel.toMap(wish),
      where: 'id = ?',
      whereArgs: [wish.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.wishes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
