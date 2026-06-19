import 'package:mycycle/core/enums/cycle_phase.dart';

/// Прогноз и текущее состояние цикла.
class CyclePrediction {
  const CyclePrediction({
    required this.currentCycleDay,
    required this.phase,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    this.nextPeriodDate,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.daysUntilNextPeriod,
    this.lastPeriodStart,
  });

  final int currentCycleDay;
  final CyclePhase phase;
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final int? daysUntilNextPeriod;
  final DateTime? lastPeriodStart;
}
