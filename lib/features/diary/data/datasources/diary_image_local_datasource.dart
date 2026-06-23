import 'package:florea/core/constants/db_tables.dart';
import 'package:florea/core/database/app_database.dart';
import 'package:florea/features/diary/data/models/diary_image_model.dart';
import 'package:florea/features/diary/domain/entities/diary_image.dart';

class DiaryImageLocalDataSource {
  DiaryImageLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<DiaryImage>> getByDiaryId(String diaryId) async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.diaryImages,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
      orderBy: 'created_at ASC',
    );
    return maps.map(DiaryImageModel.fromMap).toList();
  }

  Future<List<DiaryImage>> getAll() async {
    final database = await _db.database;
    final maps = await database.query(
      DbTables.diaryImages,
      orderBy: 'created_at DESC',
    );
    return maps.map(DiaryImageModel.fromMap).toList();
  }

  Future<void> insert(DiaryImage image) async {
    final database = await _db.database;
    await database.insert(DbTables.diaryImages, DiaryImageModel.toMap(image));
  }

  Future<void> delete(String id) async {
    final database = await _db.database;
    await database.delete(
      DbTables.diaryImages,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByDiaryId(String diaryId) async {
    final database = await _db.database;
    await database.delete(
      DbTables.diaryImages,
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );
  }
}
