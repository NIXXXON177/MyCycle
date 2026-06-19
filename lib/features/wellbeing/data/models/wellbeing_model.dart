import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/intimacy_type.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pain_location.dart';
import 'package:mycycle/core/enums/pms_symptom.dart';
import 'package:mycycle/core/utils/date_utils.dart';
import 'package:mycycle/features/wellbeing/domain/entities/wellbeing_entry.dart';

/// Маппинг WellbeingEntry <-> SQLite Map.
abstract final class WellbeingModel {
  static WellbeingEntry fromMap(Map<String, dynamic> map) {
    return WellbeingEntry(
      id: map['id'] as String,
      date: AppDateUtils.fromIso(map['date'] as String),
      mood: MoodLevel.fromValue(map['mood'] as int),
      energy: EnergyLevel.fromValue(map['energy'] as int),
      pain: PainLevel.fromValue(map['pain'] as int),
      painLocations: _parsePainLocations(map['pain_locations'] as String?),
      pmsSymptoms: _parsePmsSymptoms(map['pms_symptoms'] as String?),
      note: map['note'] as String?,
      intimacy: IntimacyType.fromValue(map['intimacy'] as int?),
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
      'pms_symptoms': entry.pmsSymptoms.map((s) => s.name).join(','),
      'note': entry.note,
      'intimacy': entry.intimacy.value,
    };
  }

  static List<PainLocation> _parsePainLocations(String? raw) {
    final locations = <PainLocation>[];
    if (raw == null || raw.isEmpty) return locations;
    for (final key in raw.split(',')) {
      final loc = PainLocation.fromKey(key.trim());
      if (loc != null) locations.add(loc);
    }
    return locations;
  }

  static List<PmsSymptom> _parsePmsSymptoms(String? raw) {
    final symptoms = <PmsSymptom>[];
    if (raw == null || raw.isEmpty) return symptoms;
    for (final key in raw.split(',')) {
      final symptom = PmsSymptom.fromKey(key.trim());
      if (symptom != null) symptoms.add(symptom);
    }
    return symptoms;
  }
}
