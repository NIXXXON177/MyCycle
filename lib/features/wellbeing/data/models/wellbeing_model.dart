import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pain_location.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Маппинг WellbeingEntry <-> SQLite Map.
abstract final class WellbeingModel {
  static WellbeingEntry fromMap(Map<String, dynamic> map) {
    final locationsRaw = map['pain_locations'] as String?;
    final locations = <PainLocation>[];
    if (locationsRaw != null && locationsRaw.isNotEmpty) {
      for (final key in locationsRaw.split(',')) {
        final loc = PainLocation.fromKey(key.trim());
        if (loc != null) locations.add(loc);
      }
    }

    return WellbeingEntry(
      id: map['id'] as String,
      date: AppDateUtils.fromIso(map['date'] as String),
      mood: MoodLevel.fromValue(map['mood'] as int),
      energy: EnergyLevel.fromValue(map['energy'] as int),
      pain: PainLevel.fromValue(map['pain'] as int),
      painLocations: locations,
      note: map['note'] as String?,
    );
  }

  static Map<String, dynamic> toMap(WellbeingEntry entry) {
    return {
      'id': entry.id,
      'date': AppDateUtils.dateToIso(entry.date),
      'mood': entry.mood.value,
      'energy': entry.energy.value,
      'pain': entry.pain.value,
      'pain_locations':
          entry.painLocations.map((l) => l.name).join(','),
      'note': entry.note,
    };
  }
}
