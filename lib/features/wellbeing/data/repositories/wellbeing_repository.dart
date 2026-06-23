import 'package:florea/core/enums/energy_level.dart';
import 'package:florea/core/enums/intimacy_type.dart';
import 'package:florea/core/enums/mood_level.dart';
import 'package:florea/core/enums/pain_level.dart';
import 'package:florea/core/utils/date_utils.dart';
import 'package:florea/features/wellbeing/data/datasources/wellbeing_local_datasource.dart';
import 'package:florea/features/wellbeing/domain/entities/wellbeing_entry.dart';
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
      pmsSymptoms: entry.pmsSymptoms,
      note: entry.note,
      intimacy: entry.intimacy,
    );
    await _dataSource.upsert(saved);
    return saved;
  }

  /// Быстрый чек-ин: сохраняет только настроение за сегодня.
  Future<void> setQuickMood(DateTime date, MoodLevel mood) async {
    final normalized = AppDateUtils.dateOnly(date);
    final existing = await getByDate(normalized);
    if (existing != null) {
      await save(existing.copyWith(mood: mood));
      return;
    }

    await saveForDate(
      date: normalized,
      entry: WellbeingEntry(
        id: '',
        date: normalized,
        mood: mood,
        energy: EnergyLevel.medium,
        pain: PainLevel.none,
      ),
    );
  }

  /// Сохраняет только отметку близости за день (остальные поля — по умолчанию).
  Future<void> setIntimacyForDate(DateTime date, IntimacyType intimacy) async {
    final normalized = AppDateUtils.dateOnly(date);
    final existing = await getByDate(normalized);
    if (existing != null) {
      await save(existing.copyWith(intimacy: intimacy));
      return;
    }

    await saveForDate(
      date: normalized,
      entry: WellbeingEntry(
        id: '',
        date: normalized,
        mood: MoodLevel.normal,
        energy: EnergyLevel.medium,
        pain: PainLevel.none,
        intimacy: intimacy,
      ),
    );
  }

  Future<void> delete(String id) => _dataSource.delete(id);
}
