import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/features/diary/data/datasources/diary_local_datasource.dart';
import 'package:mycycle/features/diary/domain/entities/diary_entry.dart';
import 'package:uuid/uuid.dart';

class DiaryRepository {
  DiaryRepository(this._dataSource);

  final DiaryLocalDataSource _dataSource;
  final _uuid = const Uuid();

  Future<List<DiaryEntry>> getAll() => _dataSource.getAll();

  Future<List<DiaryEntry>> search(String query) {
    if (query.trim().isEmpty) return getAll();
    return _dataSource.search(query.trim());
  }

  Future<DiaryEntry?> getById(String id) => _dataSource.getById(id);

  Future<void> add({
    required DateTime date,
    required String text,
    required MoodLevel mood,
  }) async {
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: _uuid.v4(),
      date: date,
      text: text,
      mood: mood,
      createdAt: now,
      updatedAt: now,
    );
    await _dataSource.insert(entry);
  }

  Future<void> update(DiaryEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _dataSource.update(updated);
  }

  Future<void> delete(String id) => _dataSource.delete(id);
}
