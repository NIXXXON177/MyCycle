import 'package:mycycle/core/enums/energy_level.dart';
import 'package:mycycle/core/enums/mood_level.dart';
import 'package:mycycle/core/enums/pain_level.dart';
import 'package:mycycle/core/enums/pain_location.dart';

/// Запись самочувствия за день.
class WellbeingEntry {
  const WellbeingEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.energy,
    required this.pain,
    this.painLocations = const [],
    this.note,
  });

  final String id;
  final DateTime date;
  final MoodLevel mood;
  final EnergyLevel energy;
  final PainLevel pain;
  final List<PainLocation> painLocations;
  final String? note;

  WellbeingEntry copyWith({
    String? id,
    DateTime? date,
    MoodLevel? mood,
    EnergyLevel? energy,
    PainLevel? pain,
    List<PainLocation>? painLocations,
    String? note,
    bool clearNote = false,
  }) {
    return WellbeingEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      pain: pain ?? this.pain,
      painLocations: painLocations ?? this.painLocations,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}
