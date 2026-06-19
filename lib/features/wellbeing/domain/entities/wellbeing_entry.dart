import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/intimacy_type.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pain_location.dart';
import 'package:mycycle/core/enums/pms_symptom.dart';

/// Запись самочувствия за день.
class WellbeingEntry {
  const WellbeingEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.energy,
    required this.pain,
    this.painLocations = const [],
    this.pmsSymptoms = const [],
    this.note,
    this.intimacy = IntimacyType.none,
  });

  final String id;
  final DateTime date;
  final MoodLevel mood;
  final EnergyLevel energy;
  final PainLevel pain;
  final List<PainLocation> painLocations;
  final List<PmsSymptom> pmsSymptoms;
  final String? note;
  final IntimacyType intimacy;

  WellbeingEntry copyWith({
    String? id,
    DateTime? date,
    MoodLevel? mood,
    EnergyLevel? energy,
    PainLevel? pain,
    List<PainLocation>? painLocations,
    List<PmsSymptom>? pmsSymptoms,
    String? note,
    IntimacyType? intimacy,
    bool clearNote = false,
  }) {
    return WellbeingEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      pain: pain ?? this.pain,
      painLocations: painLocations ?? this.painLocations,
      pmsSymptoms: pmsSymptoms ?? this.pmsSymptoms,
      note: clearNote ? null : (note ?? this.note),
      intimacy: intimacy ?? this.intimacy,
    );
  }
}
