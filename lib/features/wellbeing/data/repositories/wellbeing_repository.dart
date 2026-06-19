import 'package:mycycle/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';
import 'package:uuid/uuid.dart';

class WellbeingRepository {
  WellbeingRepository(this._dataSource);

  final WellbeingLocalDataSource _dataSource;
  final _uuid = const Uuid();

  Future<List<WellbeingEntry>> getAll() => _dataSource.getAll();

  Future<WellbeingEntry?> getByDate(DateTime date) =>
      _dataSource.getByDate(date);

  Future<void> save(WellbeingEntry entry) => _dataSource.upsert(entry);

  Future<WellbeingEntry> saveForDate({
    required DateTime date,
    String? existingId,
    required WellbeingEntry entry,
  }) async {
    final saved = WellbeingEntry(
      id: existingId ?? _uuid.v4(),
      date: date,
      mood: entry.mood,
      energy: entry.energy,
      pain: entry.pain,
      painLocations: entry.painLocations,
      note: entry.note,
    );
    await _dataSource.upsert(saved);
    return saved;
  }

  Future<void> delete(String id) => _dataSource.delete(id);
}
