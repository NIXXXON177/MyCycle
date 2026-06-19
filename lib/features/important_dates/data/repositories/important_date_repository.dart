import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/important_dates/data/datasources/important_date_local_datasource.dart';
import 'package:mycycle/features/important_dates/domain/entities/important_date.dart';
import 'package:uuid/uuid.dart';

class ImportantDateRepository {
  ImportantDateRepository(this._dataSource);

  final ImportantDateLocalDataSource _dataSource;
  final _uuid = const Uuid();

  Future<List<ImportantDate>> getAll() => _dataSource.getAll();

  Future<List<UpcomingImportantDate>> getUpcoming({
    int limit = 5,
    int withinDays = 90,
    DateTime? reference,
  }) async {
    final today = AppDateUtils.dateOnly(reference ?? DateTime.now());
    final all = await getAll();
    final upcoming = <UpcomingImportantDate>[];

    for (final entry in all) {
      final occurrence = entry.nextOccurrenceFrom(today);
      if (!entry.repeatYearly && occurrence.isBefore(today)) continue;

      final days = AppDateUtils.daysBetween(today, occurrence);
      if (days < 0 || days > withinDays) continue;

      upcoming.add(UpcomingImportantDate(entry: entry, occurrence: occurrence));
    }

    upcoming.sort((a, b) => a.occurrence.compareTo(b.occurrence));
    return upcoming.take(limit).toList();
  }

  Future<ImportantDate> create({
    required String title,
    required DateTime date,
    bool repeatYearly = false,
  }) async {
    final entry = ImportantDate(
      id: _uuid.v4(),
      title: title,
      date: AppDateUtils.dateOnly(date),
      repeatYearly: repeatYearly,
      createdAt: DateTime.now(),
    );
    await _dataSource.insert(entry);
    return entry;
  }

  Future<void> update(ImportantDate entry) => _dataSource.update(entry);

  Future<void> delete(String id) => _dataSource.delete(id);
}
